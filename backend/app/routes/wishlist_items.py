from typing import Optional
from fastapi import APIRouter, Depends, Request, HTTPException, Body
from ..utils.logger import logger
from sqlalchemy.orm import Session
from ..models import WishItemRequest
from ..auth import verify_token
from ..db.database import SessionLocal
from ..db.models import WishItemDB, UserDB
from ..db.crud import (
    get_wishlist_by_id, get_items_for_wishlist, add_item_to_wishlist
)


router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Create a wishlist item (owner only)
@router.post("/wishlists/{wishlist_id}/items")
def add_item_to_wishlist_route(wishlist_id: int, item: WishItemRequest, request: Request = None, user=Depends(verify_token), db: Session = Depends(get_db)):
    logger.info(f"[add_item_to_wishlist] User {user['uid']} adding item to wishlist {wishlist_id}")
    wishlist = get_wishlist_by_id(db, wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if wishlist.owner_id != user['uid']:
        raise HTTPException(status_code=403, detail="Not allowed to edit this wishlist")
    # Check for duplicate item id
    if any(existing_item.id == item.id for existing_item in get_items_for_wishlist(db, wishlist_id)):
        raise HTTPException(status_code=400, detail="Item with this ID already exists")
    db_item = WishItemDB(
        wishlist_id=wishlist_id,
        name=item.name,
        reserved=item.reserved,
        reserved_by=item.reserved_by,
        link=item.link
    )
    db_item = add_item_to_wishlist(db, db_item)
    return WishItemRequest(
        id=db_item.id,
        name=db_item.name,
        reserved=db_item.reserved,
        reserved_by=db_item.reserved_by,
        link=db_item.link
    )


# Get all items for a wishlist (owner or shared_with)
@router.get("/wishlists/{wishlist_id}/items", response_model=list[WishItemRequest])
def get_all_items_for_wishlist(wishlist_id: int, user=Depends(verify_token), db: Session = Depends(get_db)):
    logger.info(f"[get_all_items_for_wishlist] User {user['uid']} fetching items for wishlist {wishlist_id}")
    wishlist = get_wishlist_by_id(db, wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    # Only allow access if user is owner or in shared_with
    user_id = user['uid']
    shared_with_ids = [sw.uid for sw in wishlist.shared_with]
    if wishlist.owner_id != user_id and user_id not in shared_with_ids:
        raise HTTPException(status_code=403, detail="Not allowed to view items in this wishlist")
    items = get_items_for_wishlist(db, wishlist_id)
    # Collect all reserved_by user IDs (excluding None)
    reserved_by_ids = set(item.reserved_by for item in items if item.reserved_by)
    user_map = {}
    if reserved_by_ids:
        users = db.query(UserDB).filter(UserDB.uid.in_(reserved_by_ids)).all()
        user_map = {user.uid: f"{user.first_name} {user.last_name}".capitalize() for user in users}
    return [WishItemRequest(
        id=item.id,
        name=item.name,
        reserved=item.reserved,
        reserved_by=item.reserved_by,
        reserved_by_name=user_map.get(item.reserved_by) if item.reserved_by else None,
        link=item.link
    ) for item in items]


# Update a wishlist item (owner only)
@router.put("/wishlists/{wishlist_id}/items/{item_id}")
def update_wishlist_item(wishlist_id: int, item_id: int, item_update: dict = Body(...), user=Depends(verify_token), db: Session = Depends(get_db)):
    logger.info(f"[update_wishlist_item] User {user['uid']} updating item {item_id} in wishlist {wishlist_id}")
    wishlist = get_wishlist_by_id(db, wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if wishlist.owner_id != user['uid']:
        raise HTTPException(status_code=403, detail="Not allowed to edit this wishlist")
    item = db.query(WishItemDB).filter(WishItemDB.id == item_id, WishItemDB.wishlist_id == wishlist_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    if 'name' in item_update:
        item.name = item_update['name']
    if 'link' in item_update:
        item.link = item_update['link']
    db.commit()
    db.refresh(item)
    return {"message": "Item updated!"}


# Delete a wishlist item (owner only)
@router.delete("/wishlists/{wishlist_id}/items/{item_id}")
def delete_wishlist_item(wishlist_id: int, item_id: int, user=Depends(verify_token), db: Session = Depends(get_db)):
    logger.info(f"[delete_wishlist_item] User {user['uid']} deleting item {item_id} from wishlist {wishlist_id}")
    wishlist = get_wishlist_by_id(db, wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if wishlist.owner_id != user['uid']:
        raise HTTPException(status_code=403, detail="Not allowed to delete from this wishlist")
    item = db.query(WishItemDB).filter(WishItemDB.id == item_id, WishItemDB.wishlist_id == wishlist_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    db.delete(item)
    db.commit()
    return {"message": "Item deleted!"}


# Reserve a gift (shared_with only)
@router.post("/wishlists/{wishlist_id}/reserve/{item_id}")
def reserve_gift(wishlist_id: int, item_id: int, reserved_by: Optional[str] = None, request: Request = None, user=Depends(verify_token), db: Session = Depends(get_db)):
    logger.info(f"[reserve_gift] User {user['uid']} reserving item {item_id} in wishlist {wishlist_id}")
    wishlist = get_wishlist_by_id(db, wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    user_id = user['uid']
    if wishlist.owner_id == user_id and user_id not in (wishlist.shared_with or []):
        raise HTTPException(status_code=403, detail="Not allowed to reserve this wishlist")
    item = db.query(WishItemDB).filter(WishItemDB.id == item_id, WishItemDB.wishlist_id == wishlist_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    user_id = user['uid']
    # If already reserved, allow un-reserve only if reserved_by matches user
    if item.reserved:
        if item.reserved_by == user_id:
            item.reserved = False
            item.reserved_by = None
            db.commit()
            db.refresh(item)
            return {"message": "Gift un-reserved!"}
        else:
            raise HTTPException(status_code=400, detail="Item already reserved")
    # Otherwise, reserve as normal
    item.reserved = True
    item.reserved_by = reserved_by
    db.commit()
    db.refresh(item)
    return {"message": "Gift reserved!"}

