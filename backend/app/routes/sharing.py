from fastapi import APIRouter, Depends, Request, HTTPException, Body, BackgroundTasks
from sqlalchemy.orm import Session
import uuid
import secrets

from ..utils.logger import logger
from ..auth import verify_token
from ..models import EmailRequest
from ..db.models import SharedWithGroupDB, UserDB, WishListDB
from ..db.crud import get_wishlist_by_id, share_wishlist_with_user
from ..db.database import SessionLocal
from ..utils.email_utils import send_invite_email_background, send_shared_email_background, is_valid_email
from ..config import settings

router = APIRouter()

share_tokens = {}

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()



@router.post("/wishlists/{wishlist_id}/share-group")
def share_wishlist_with_group(wishlist_id: int, group_id: int = Body(...), user=Depends(verify_token), db: Session = Depends(get_db)):
    """Share a wishlist with a group."""
    logger.info(f"[share_wishlist_with_group] User {user['uid']} sharing wishlist {wishlist_id} with group {group_id}")
    try:
        wishlist = db.query(WishListDB).filter(WishListDB.id == wishlist_id).first()
        if not wishlist:
            logger.warning(f"[share_wishlist_with_group] Wishlist {wishlist_id} not found")
            raise HTTPException(status_code=404, detail="Wishlist not found")
        if wishlist.owner_id != user['uid']:
            logger.warning(f"[share_wishlist_with_group] User {user['uid']} not allowed to share wishlist {wishlist_id}")
            raise HTTPException(status_code=403, detail="Not allowed to share this wishlist")
        exists = db.query(SharedWithGroupDB).filter_by(wishlist_id=wishlist_id, group_id=group_id).first()
        if exists:
            logger.warning(f"[share_wishlist_with_group] Wishlist {wishlist_id} already shared with group {group_id}")
            raise HTTPException(status_code=400, detail="Wishlist already shared with this group.")
        db.add(SharedWithGroupDB(wishlist_id=wishlist_id, group_id=group_id))
        db.commit()
        logger.info(f"[share_wishlist_with_group] Wishlist {wishlist_id} shared with group {group_id}")
        return {"message": "Wishlist shared with group."}
    except Exception as e:
        logger.error(f"[share_wishlist_with_group] Error: {e}")
        raise


@router.post("/wishlists/{wishlist_id}/share")
def share_wishlist_with_user(
    wishlist_id: int,
    request: EmailRequest,
    background_tasks: BackgroundTasks,
    current_user=Depends(verify_token),
    db: Session = Depends(get_db),
):
    """Share a wishlist with a user"""
    logger.info(f"[share_wishlist] User {current_user['uid']} generating share link for wishlist {wishlist_id}")
    try:
        email = request.email
        if not is_valid_email(email):
            raise HTTPException(status_code=400, detail="Invalid email address")
        user_to_add = db.query(UserDB).filter(UserDB.email == email).first()
        current_user = db.query(UserDB).filter(UserDB.uid == current_user['uid']).first()

        if user_to_add:
            wishlist = get_wishlist_by_id(db, wishlist_id)
            if not wishlist:
                logger.warning(f"[share_wishlist] Wishlist {wishlist_id} not found")
                raise HTTPException(status_code=404, detail="Wishlist not found")
            if wishlist.owner_id != current_user.uid:
                logger.warning(f"[share_wishlist] User {current_user.uid} not allowed to share wishlist {wishlist_id}")
                raise HTTPException(status_code=403, detail="Not allowed to share this wishlist")

            wishlist.shared_with.append(user_to_add)
            db.commit()
            # Send notification email
            send_shared_email_background(
                background_tasks,
                f"{user_to_add.first_name} {user_to_add.last_name}",
                user_to_add.email,
                f"{current_user.first_name} {current_user.last_name}",
                logger=logger
            )
            return {"message": "Wishlist shared and email sent."}
        else:
            token = secrets.token_urlsafe(16)
            share_tokens[token] = (wishlist_id, current_user.uid)
            invite_link = f"{settings.WEBSITE_URL}/share/{token}"
            logger.info(f"[share_wishlist] Share link generated for wishlist {wishlist_id} by user {current_user.uid}")
            send_invite_email_background(background_tasks, email, invite_link, logger)
            logger.info(f"[share_wishlist] Invite sent to {email} for wishlist {wishlist_id}")
            return {"message": f"Invite sent to {email}."}
    except Exception as e:
        logger.error(f"[share_wishlist] Error: {e}")
        raise


@router.post("/wishlists/share/{token}")
def accept_shared_wishlist(token: str, request: Request, user=Depends(verify_token), db: Session = Depends(get_db)):
    try:
        entry = share_tokens.get(token)
        if not entry:
            logger.warning(f"[accept_shared_wishlist] Invalid or expired share link: {token}")
            raise HTTPException(status_code=404, detail="Invalid or expired share link")
        wishlist_id, owner_id = entry
        wishlist = get_wishlist_by_id(db, wishlist_id)
        if not wishlist:
            logger.warning(f"[accept_shared_wishlist] Wishlist {wishlist_id} not found for token {token}")
            raise HTTPException(status_code=404, detail="Wishlist not found")
        # If user is authenticated, use their uid. Otherwise, create a guest user.
        guest_mode = False
        guest_uid = None
        try:
            user_id = user['uid']
        except Exception:
            guest_mode = True
            guest_uid = f"guest-{uuid.uuid4()}"
            # Create guest user in DB if not exists
            if not db.query(UserDB).filter(UserDB.uid == guest_uid).first():
                db.add(UserDB(uid=guest_uid, first_name="Guest", last_name="User", email=None))
                db.commit()
        if guest_mode:
            share_wishlist_with_user(db, wishlist_id, guest_uid)
            del share_tokens[token]
            logger.info(f"[accept_shared_wishlist] Guest user {guest_uid} added to shared_with for wishlist {wishlist_id}")
            return {"message": "Wishlist shared successfully!", "guest_uid": guest_uid}
        else:
            share_wishlist_with_user(db, wishlist_id, user_id)
            del share_tokens[token]
            logger.info(f"[accept_shared_wishlist] User {user_id} added to shared_with for wishlist {wishlist_id}")
            return {"message": "Wishlist shared successfully!"}
    except Exception as e:
        logger.error(f"[accept_shared_wishlist] Error: {e}")
        raise


@router.get("/share/{token}/info")
def get_invite_info(token: str, db: Session = Depends(get_db)):
    entry = share_tokens.get(token)
    if not entry:
        raise HTTPException(status_code=404, detail="Invalid or expired invite link")
    wishlist_id, owner_id = entry
    owner = db.query(UserDB).filter(UserDB.uid == owner_id).first()
    return {
        "wishlist_id": wishlist_id,
        "invite_username": f"{owner.first_name} {owner.last_name}" if owner else "Someone"
    }


@router.post("/wishlists/share/{token}/accept")
def accept_invite_after_signup(token: str, user_id: str = Body(...), db: Session = Depends(get_db)):
    entry = share_tokens.get(token)
    if not entry:
        raise HTTPException(status_code=404, detail="Invalid or expired invite link")
    wishlist_id, _ = entry
    share_wishlist_with_user(db, wishlist_id, user_id)
    del share_tokens[token]
    return {"message": "You now have access to the shared wishlist!"}


@router.get("/wishlists/{wishlist_id}/shared-users")
def get_shared_users(
    wishlist_id: int,
    user=Depends(verify_token),
    db: Session = Depends(get_db),
):
    """Return a list of emails the wishlist is shared with."""
    wishlist = db.query(WishListDB).filter(WishListDB.id == wishlist_id).first()
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    # Only owner can see shared users
    if wishlist.owner_id != user["uid"]:
        raise HTTPException(status_code=403, detail="Not allowed")
    from ..db.crud import get_shared_user_emails_for_wishlist
    return get_shared_user_emails_for_wishlist(db, wishlist_id)


@router.post("/wishlists/{wishlist_id}/unshare")
def unshare_wishlist_with_user_endpoint(
    wishlist_id: int,
    payload: dict = Body(...),
    user=Depends(verify_token),
    db: Session = Depends(get_db),
):
    """Unshare a wishlist with a user by email."""
    email = payload.get("email")
    if not email:
        raise HTTPException(status_code=400, detail="Email required")
    wishlist = db.query(WishListDB).filter(WishListDB.id == wishlist_id).first()
    if not wishlist:
        raise HTTPException(status_code=404, detail="Wishlist not found")
    # Only owner can unshare
    if wishlist.owner_id != user["uid"]:
        raise HTTPException(status_code=403, detail="Not allowed")
    from ..db.crud import unshare_wishlist_with_user
    unshare_wishlist_with_user(db, wishlist_id, email)
    return {"message": f"Unshared with {email}"}
