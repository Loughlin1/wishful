from typing import Optional
from fastapi import APIRouter, Depends, Request, HTTPException, Body
from fastapi.responses import JSONResponse
import secrets

from ..models import WishList, WishItem, WishListCreate
from ..auth import verify_token
from ..db import wishlists

router = APIRouter()

# Create a wishlist item (owner only)
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


# Update a wishlist item (owner only)
@router.put("/wishlists/{wishlist_id}/items/{item_id}")
def update_wishlist_item(wishlist_id: int, item_id: int, item_update: dict = Body(...), user=Depends(verify_token)):
    wishlist = wishlists.get(wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if wishlist.owner_id != user['uid']:
        raise HTTPException(status_code=403, detail="Not allowed to edit this wishlist")
    for item in wishlist.items:
        if item.id == item_id:
            if 'name' in item_update:
                item.name = item_update['name']
            # Optionally update other fields
            return {"message": "Item updated!"}
    raise HTTPException(status_code=404, detail="Item not found")


# Delete a wishlist item (owner only)
@router.delete("/wishlists/{wishlist_id}/items/{item_id}")
def delete_wishlist_item(wishlist_id: int, item_id: int, user=Depends(verify_token)):
    wishlist = wishlists.get(wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if wishlist.owner_id != user['uid']:
        raise HTTPException(status_code=403, detail="Not allowed to delete from this wishlist")
    for i, item in enumerate(wishlist.items):
        if item.id == item_id:
            del wishlist.items[i]
            return {"message": "Item deleted!"}
    raise HTTPException(status_code=404, detail="Item not found")


# Reserve a gift (shared_with only)
@router.post("/wishlists/{wishlist_id}/reserve/{item_id}")
def reserve_gift(wishlist_id: int, item_id: int, reserved_by: Optional[str] = None, request: Request = None, user=Depends(verify_token)):
    wishlist = wishlists.get(wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    user_id = user['uid']
    if wishlist.owner_id == user_id and user_id not in (wishlist.shared_with or []):
        raise HTTPException(status_code=403, detail="Not allowed to reserve this wishlist")
    for item in wishlist.items:
        if item.id == item_id:
            if item.reserved:
                raise HTTPException(status_code=400, detail="Item already reserved")
            item.reserved = True
            item.reserved_by = reserved_by
            return {"message": "Gift reserved!"}
    raise HTTPException(status_code=404, detail="Item not found")

