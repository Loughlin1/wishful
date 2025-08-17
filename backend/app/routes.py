from fastapi import APIRouter, HTTPException, Body, Depends, Request
from typing import List
from .models import WishList, WishItem
from .auth import verify_token

router = APIRouter()

# In-memory store (replace with DB/Firebase in production)
wishlists = {
    1: WishList(
        id=1,
        owner="Demo User",
        owner_id="demo_uid",
        items=[
            WishItem(id=1, name="Book", reserved=False),
            WishItem(id=2, name="Headphones", reserved=True, reserved_by="Alice"),
        ],
        shared_with=["demo_friend_uid"],
    )
}

@router.get("/wishlists", response_model=List[WishList])
def get_wishlists(request: Request, user=Depends(verify_token)):
    user_id = user['uid']
    # Return wishlists owned by or shared with the user
    return [w for w in wishlists.values() if w.owner_id == user_id or user_id in (w.shared_with or [])]

@router.post("/wishlists", response_model=WishList)
def create_wishlist(wishlist: WishList, request: Request, user=Depends(verify_token)):
    if wishlist.id in wishlists:
        raise HTTPException(status_code=400, detail="Wishlist already exists")
    # Set owner_id to authenticated user
    wishlist.owner_id = user['uid']
    wishlists[wishlist.id] = wishlist
    return wishlist

@router.post("/wishlists/{wishlist_id}/items")
def add_item_to_wishlist(wishlist_id: int, item: WishItem = Body(...), request: Request = None, user=Depends(verify_token)):
    wishlist = wishlists.get(wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if wishlist.owner_id != user['uid']:
        raise HTTPException(status_code=403, detail="Not allowed to edit this wishlist")
    if any(existing_item.id == item.id for existing_item in wishlist.items):
        raise HTTPException(status_code=400, detail="Item with this ID already exists")
    wishlist.items.append(item)
    return {"message": "Item added!"}

@router.post("/wishlists/{wishlist_id}/reserve/{item_id}")
def reserve_gift(wishlist_id: int, item_id: int, reserved_by: str, request: Request = None, user=Depends(verify_token)):
    wishlist = wishlists.get(wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    # Only allow if user is owner or shared_with
    user_id = user['uid']
    if wishlist.owner_id != user_id and user_id not in (wishlist.shared_with or []):
        raise HTTPException(status_code=403, detail="Not allowed to reserve this wishlist")
    for item in wishlist.items:
        if item.id == item_id:
            if item.reserved:
                raise HTTPException(status_code=400, detail="Item already reserved")
            item.reserved = True
            item.reserved_by = reserved_by
            return {"message": "Gift reserved!"}
    raise HTTPException(status_code=404, detail="Item not found")

@router.get("/recommendations/{user_id}")
def get_recommendations(user_id: str):
    # TODO: Integrate ML recommendation logic
    return {"recommendations": ["Gift Card", "Book", "Headphones"]}
