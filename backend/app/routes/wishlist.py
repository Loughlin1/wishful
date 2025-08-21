from typing import Annotated
from fastapi import APIRouter, Depends, Request, HTTPException, Body
from ..utils.logger import logger
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from ..models import WishListRequest, CreateWishListRequest, TagEnum
from ..auth import verify_token
from ..db.database import SessionLocal
from ..db.models import WishListDB, WishItemDB
from ..db.crud import (
    get_wishlist_by_id, get_wishlists_for_user, create_wishlist as crud_create_wishlist
)


router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Read wishlists (owner or shared_with)
@router.get("/wishlists", response_model=list[WishListRequest])
def get_wishlists(request: Request, user=Depends(verify_token), db: Session = Depends(get_db)):
    logger.info(f"[get_wishlists] User {user['uid']} fetching wishlists")
    user_id = user['uid']
    db_wishlists = get_wishlists_for_user(db, user_id)
    result = []
    for db_wishlist in db_wishlists:
        shared_with = [sw.uid for sw in db_wishlist.shared_with]
        result.append(WishListRequest(
            id=db_wishlist.id,
            name=db_wishlist.name,
            owner_id=db_wishlist.owner_id,
            owner_first_name=db_wishlist.owner_user.first_name.capitalize() if db_wishlist.owner_user.first_name else "",
            owner_last_name=db_wishlist.owner_user.last_name.capitalize() if db_wishlist.owner_user.last_name else "",
            items=[],  # Items will be fetched via a separate endpoint
            shared_with=shared_with,
            tag=db_wishlist.tag
        ))
    return result


# Create a wishlist (owner only)
@router.post("/wishlists", response_model=WishListRequest)
def create_wishlist(wishlist: CreateWishListRequest, request: Request, user=Depends(verify_token), db: Session = Depends(get_db)):
    logger.info(f"[create_wishlist] User {user['uid']} creating wishlist {wishlist.id}")
    if get_wishlist_by_id(db, wishlist.id):
        raise HTTPException(status_code=400, detail="Wishlist already exists")
    
    db_wishlist = WishListDB(
        id=wishlist.id,
        owner_id=user['uid'],
        name=wishlist.name,
        tag=wishlist.tag,
    )
    db_wishlist = crud_create_wishlist(db, db_wishlist)
    return WishListRequest(
        id=db_wishlist.id,
        name=db_wishlist.name,
        owner_id=db_wishlist.owner_id,
        owner_first_name=db_wishlist.owner_user.first_name,
        owner_last_name=db_wishlist.owner_user.last_name,
        items=[],
        shared_with=[],
        tag=db_wishlist.tag
    )


# Edit a wishlist (owner only)
@router.put("/wishlists/{wishlist_id}", response_model=WishListRequest)
def update_wishlist(wishlist_id: int, wishlist_update: WishListRequest, request: Request, user=Depends(verify_token), db: Session = Depends(get_db)):
    logger.info(f"[update_wishlist] User {user['uid']} updating wishlist {wishlist_id}")
    wishlist = get_wishlist_by_id(db, wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if wishlist.owner_id != user['uid']:
        raise HTTPException(status_code=403, detail="Not allowed to edit this wishlist")
    wishlist.name = wishlist_update.name
    wishlist.tag = wishlist_update.tag
    wishlist.shared_with = wishlist_update.shared_with or []
    db.commit()
    db.refresh(wishlist)
    return wishlist


# Delete a wishlist (owner only)
@router.delete("/wishlists/{wishlist_id}")
def delete_wishlist(wishlist_id: int, user=Depends(verify_token), db: Session = Depends(get_db)):
    logger.info(f"[delete_wishlist] User {user['uid']} deleting wishlist {wishlist_id}")
    wishlist = get_wishlist_by_id(db, wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if wishlist.owner_id != user['uid']:
        raise HTTPException(status_code=403, detail="Not allowed to delete this wishlist")
    db.delete(wishlist)
    db.commit()
    return {"message": "Wishlist deleted!"}


# Endpoint to get available tag options
@router.get("/wishlist-tags", response_model=list[str])
def get_wishlist_tags():
    logger.info(f"[get_wishlist_tags] Fetching wishlist tags")
    return [tag.value for tag in TagEnum]

