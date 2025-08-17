from fastapi import APIRouter, Depends, Request, HTTPException
from ..models import WishList
from ..auth import verify_token
from ..db import wishlists, share_tokens
from ..config import settings
import secrets

router = APIRouter()


@router.post("/wishlists/{wishlist_id}/share")
def share_wishlist(wishlist_id: int, request: Request, user=Depends(verify_token)):
    wishlist = wishlists.get(wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if wishlist.owner_id != user['uid']:
        raise HTTPException(status_code=403, detail="Not allowed to share this wishlist")
    token = secrets.token_urlsafe(16)
    share_tokens[token] = (wishlist_id, user['uid'])
    link = f"{settings.WEBSITE_URL}/share/{token}"
    return {"link": link, "token": token}

@router.post("/wishlists/share/{token}")
def accept_shared_wishlist(token: str, request: Request, user=Depends(verify_token)):
    entry = share_tokens.get(token)
    if not entry:
        raise HTTPException(status_code=404, detail="Invalid or expired share link")
    wishlist_id, owner_id = entry
    wishlist = wishlists.get(wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if user['uid'] not in (wishlist.shared_with or []):
        wishlist.shared_with.append(user['uid'])
    del share_tokens[token]
    return {"message": "Wishlist shared successfully!"}
