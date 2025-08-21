from fastapi import APIRouter, Depends, Body, Query, BackgroundTasks, HTTPException
from sqlalchemy.orm import Session

from ..auth import verify_token
from ..db.models import GroupDB, GroupMemberDB, UserDB
from ..db.database import SessionLocal
from ..utils.logger import logger
from ..utils.email_utils import send_invite_email_background
from ..config import settings


router = APIRouter()


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



# Group search endpoint for sharing dialog
@router.get("/groups/search")
def search_groups(
    q: str = Query(..., description="Search query for group name"),
    limit: int = Query(10, description="Max results to return"),
    db: Session = Depends(get_db)
):
    logger.info(f"[search_groups] Searching groups with query: {q}")
    query = db.query(GroupDB).filter(
        GroupDB.name.ilike(f"%{q}%")
    ).limit(limit)
    groups = query.all()
    return [{
        "id": group.id,
        "name": group.name,
        "owner_id": group.owner_id
    } for group in groups]


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
