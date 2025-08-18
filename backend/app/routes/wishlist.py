from typing import Optional
from fastapi import APIRouter, Depends, Request, HTTPException, Body
from fastapi.responses import JSONResponse
import secrets

from ..models import WishList, WishListCreate, TagEnum
from ..auth import verify_token
from ..db import wishlists


router = APIRouter()


# Read wishlists (owner or shared_with)
@router.get("/wishlists", response_model=list[WishList])
def get_wishlists(request: Request, user=Depends(verify_token)):
    user_id = user['uid']
    return [w for w in wishlists.values() if w.owner_id == user_id or user_id in (w.shared_with or [])]


# Create a wishlist (owner only)
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
        tag=wishlist.tag
    )
    wishlists[new_wishlist.id] = new_wishlist
    return new_wishlist


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
    wishlist.tag = wishlist_update.tag
    wishlist.shared_with = wishlist_update.shared_with or []
    wishlists[wishlist_id] = wishlist
    return wishlist


# Delete a wishlist (owner only)
@router.delete("/wishlists/{wishlist_id}")
def delete_wishlist(wishlist_id: int, user=Depends(verify_token)):
    wishlist = wishlists.get(wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if wishlist.owner_id != user['uid']:
        raise HTTPException(status_code=403, detail="Not allowed to delete this wishlist")
    del wishlists[wishlist_id]
    return {"message": "Wishlist deleted!"}


# Endpoint to get available tag options
@router.get("/wishlist-tags", response_model=list[str])
def get_wishlist_tags():
    return [tag.value for tag in TagEnum]

