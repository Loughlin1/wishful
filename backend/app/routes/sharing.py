
from fastapi import APIRouter, Depends, Request, HTTPException
from sqlalchemy.orm import Session
from ..models import WishListRequest
from ..auth import verify_token
from ..db.database import SessionLocal
from ..db.crud import get_wishlist_by_id, share_wishlist_with_user
from ..config import settings
import secrets

router = APIRouter()

share_tokens = {}

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/wishlists/{wishlist_id}/share")
def share_wishlist(wishlist_id: int, request: Request, user=Depends(verify_token), db: Session = Depends(get_db)):
    wishlist = get_wishlist_by_id(db, wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    if wishlist.owner_id != user['uid']:
        raise HTTPException(status_code=403, detail="Not allowed to share this wishlist")
    token = secrets.token_urlsafe(16)
    share_tokens[token] = (wishlist_id, user['uid'])
    link = f"{settings.WEBSITE_URL}/share/{token}"
    return {"link": link, "token": token}

@router.post("/wishlists/share/{token}")
def accept_shared_wishlist(token: str, request: Request, user=Depends(verify_token), db: Session = Depends(get_db)):
    entry = share_tokens.get(token)
    if not entry:
        raise HTTPException(status_code=404, detail="Invalid or expired share link")
    wishlist_id, owner_id = entry
    wishlist = get_wishlist_by_id(db, wishlist_id)
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    # Add user to shared_with table
    share_wishlist_with_user(db, wishlist_id, user['uid'])
    del share_tokens[token]
    return {"message": "Wishlist shared successfully!"}
