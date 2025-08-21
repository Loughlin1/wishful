from fastapi import APIRouter, Depends, Request, HTTPException, Body, BackgroundTasks
from ..utils.logger import logger
from sqlalchemy.orm import Session
from ..auth import verify_token
from ..models import EmailRequest
from ..db.models import GroupDB, GroupMemberDB, SharedWithGroupDB, UserDB, WishListDB
from ..db.crud import get_wishlist_by_id, share_wishlist_with_user
from ..db.database import SessionLocal
from ..utils.email_utils import send_invite_email_background
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


@router.post("/groups")
def create_group(name: str = Body(...), user=Depends(verify_token), db: Session = Depends(get_db)):
    """Create a new group."""
    logger.info(f"[create_group] User {user['uid']} creating group '{name}'")
    try:
        group = GroupDB(name=name, owner_id=user['uid'])
        db.add(group)
        db.commit()
        db.refresh(group)
        db.add(GroupMemberDB(group_id=group.id, user_id=user['uid']))
        db.commit()
        logger.info(f"[create_group] Group created: id={group.id}, name={group.name}")
        return {"group_id": group.id, "name": group.name}
    except Exception as e:
        logger.error(f"[create_group] Error: {e}")
        raise


@router.post("/groups/{group_id}/members")
def add_member_to_group(
    group_id: int,
    background_tasks: BackgroundTasks,
    email: str = Body(...),
    db: Session = Depends(get_db)
):
    """Add a new member to an existing group. If user does not exist, send invite email."""
    logger.info(f"[add_member_to_group] Add member to group {group_id} with email {email}")
    try:
        user = db.query(UserDB).filter(UserDB.email == email).first()
        if not user:
            group = db.query(GroupDB).filter(GroupDB.id == group_id).first()
            group_name = group.name if group else None
            invite_link = f"{settings.WEBSITE_URL}/invite?group_id={group_id}&email={email}"
            send_invite_email_background(background_tasks, email, invite_link, group_name)
            logger.info(f"[add_member_to_group] Invite sent to {email} for group {group_id}")
            return {"message": f"Invite sent to {email}."}
        exists = db.query(GroupMemberDB).filter_by(group_id=group_id, user_id=user.uid).first()
        if exists:
            logger.warning(f"[add_member_to_group] User {user.uid} already a member of group {group_id}")
            raise HTTPException(status_code=400, detail="User already a member of group.")
        db.add(GroupMemberDB(group_id=group_id, user_id=user.uid))
        db.commit()
        logger.info(f"[add_member_to_group] User {user.uid} added to group {group_id}")
        return {"message": f"User {email} added to group."}
    except Exception as e:
        logger.error(f"[add_member_to_group] Error: {e}")
        raise


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
def share_wishlist(
    wishlist_id: int,
    request: EmailRequest,
    background_tasks: BackgroundTasks,
    user=Depends(verify_token),
    db: Session = Depends(get_db)
):
    """Share a wishlist with a user"""
    logger.info(f"[share_wishlist] User {user['uid']} generating share link for wishlist {wishlist_id}")
    try:
        email = request.email
        wishlist = get_wishlist_by_id(db, wishlist_id)
        if not wishlist:
            logger.warning(f"[share_wishlist] Wishlist {wishlist_id} not found")
            raise HTTPException(status_code=404, detail="Wishlist not found")
        if wishlist.owner_id != user['uid']:
            logger.warning(f"[share_wishlist] User {user['uid']} not allowed to share wishlist {wishlist_id}")
            raise HTTPException(status_code=403, detail="Not allowed to share this wishlist")
        token = secrets.token_urlsafe(16)
        share_tokens[token] = (wishlist_id, user['uid'])
        invite_link = f"{settings.WEBSITE_URL}/share/{token}"
        logger.info(f"[share_wishlist] Share link generated for wishlist {wishlist_id} by user {user['uid']}")
        send_invite_email_background(background_tasks, email, invite_link)
        logger.info(f"[share_wishlist] Invite sent to {email} for wishlist {wishlist_id}")
        return {"message": f"Invite sent to {email}."}
    except Exception as e:
        logger.error(f"[share_wishlist] Error: {e}")
        raise


@router.post("/wishlists/share/{token}")
def accept_shared_wishlist(token: str, request: Request, user=Depends(verify_token), db: Session = Depends(get_db)):
    logger.info(f"[accept_shared_wishlist] User {user['uid']} accepting shared wishlist with token {token}")
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
        share_wishlist_with_user(db, wishlist_id, user['uid'])
        del share_tokens[token]
        logger.info(f"[accept_shared_wishlist] User {user['uid']} added to shared_with for wishlist {wishlist_id}")
        return {"message": "Wishlist shared successfully!"}
    except Exception as e:
        logger.error(f"[accept_shared_wishlist] Error: {e}")
        raise

