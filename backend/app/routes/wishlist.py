from typing import Optional
from fastapi import APIRouter, Depends, Request, HTTPException
from fastapi.responses import JSONResponse
import secrets

from ..models import WishList, WishItem, WishListCreate
from ..auth import verify_token
from ..db import wishlists


router = APIRouter()

share_tokens = {}

@router.get("/wishlists", response_model=list[WishList])
def get_wishlists(request: Request, user=Depends(verify_token)):
    user_id = user['uid']
    return [w for w in wishlists.values() if w.owner_id == user_id or user_id in (w.shared_with or [])]

@router.post("/wishlists", response_model=WishList)
def create_wishlist(wishlist: WishListCreate, request: Request, user=Depends(verify_token)):
    if wishlist.id in wishlists:
        raise HTTPException(status_code=400, detail="Wishlist already exists")
    new_wishlist = WishList(
        id=wishlist.id,
        owner=wishlist.owner,
        owner_id=user['uid'],
        items=wishlist.items,
        shared_with=wishlist.shared_with or [],
    )
    wishlists[new_wishlist.id] = new_wishlist
    return new_wishlist

@router.post("/wishlists/{wishlist_id}/items")
def add_item_to_wishlist(wishlist_id: int, item: WishItem, request: Request = None, user=Depends(verify_token)):
    wishlist = wishlists.get(wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if wishlist.owner_id != user['uid']:
        raise HTTPException(status_code=403, detail="Not allowed to edit this wishlist")
    if any(existing_item.id == item.id for existing_item in wishlist.items):
        raise HTTPException(status_code=400, detail="Item with this ID already exists")
    wishlist.items.append(item)
    return {"message": "Item added!"}


# Edit a wishlist (owner only)
@router.put("/wishlists/{wishlist_id}", response_model=WishList)
def update_wishlist(wishlist_id: int, wishlist_update: WishListCreate, request: Request, user=Depends(verify_token)):
    wishlist = wishlists.get(wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if wishlist.owner_id != user['uid']:
        raise HTTPException(status_code=403, detail="Not allowed to edit this wishlist")
    wishlist.owner = wishlist_update.owner
    wishlist.items = wishlist_update.items
    wishlist.shared_with = wishlist_update.shared_with or []
    wishlists[wishlist_id] = wishlist
    return wishlist


# Reserve a gift (owner or shared_with)
@router.post("/wishlists/{wishlist_id}/reserve/{item_id}")
def reserve_gift(wishlist_id: int, item_id: int, reserved_by: Optional[str] = None, request: Request = None, user=Depends(verify_token)):
    wishlist = wishlists.get(wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    user_id = user['uid']
    if wishlist.owner_id != user_id and user_id not in (wishlist.shared_with or []):
        raise HTTPException(status_code=403, detail="Not allowed to reserve this wishlist")
    for item in wishlist.items:
        if item.id == item_id:
            if item.reserved:
                raise HTTPException(status_code=400, detail="Item already reserved")
            item.reserved = True
            item.reserved_by = reserved_by or user_id
            return {"message": "Gift reserved!"}
    raise HTTPException(status_code=404, detail="Item not found")

