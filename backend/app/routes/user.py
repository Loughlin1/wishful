from fastapi import APIRouter, HTTPException, Depends, Request, Query
from ..utils.logger import logger
from sqlalchemy.orm import Session
from ..models import UserRequest
from ..db.database import SessionLocal
from ..db.crud import get_user_by_uid, create_user
from sqlalchemy.orm import Session
from ..db.models import UserDB
from ..auth import verify_token


router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/register", response_model=UserRequest)
def register_user(user: UserRequest, request: Request, db: Session = Depends(get_db)):
    logger.info(f"[register_user] Registering user {user.uid}")
    if get_user_by_uid(db, user.uid):
        raise HTTPException(status_code=400, detail="User already exists")
    create_user(db, user)
    return user


# User search endpoint for sharing dialog
@router.get("/search", response_model=list[UserRequest])
def search_users(
    q: str = Query(..., description="Search query for user email or name"),
    limit: int = Query(10, description="Max results to return"),
    db: Session = Depends(get_db)
):
    logger.info(f"[search_users] Searching users with query: {q}")
    query = db.query(UserDB).filter(
        (UserDB.email.ilike(f"%{q}%")) |
        (UserDB.first_name.ilike(f"%{q}%")) |
        (UserDB.last_name.ilike(f"%{q}%"))
    ).limit(limit)
    users = query.all()
    return [UserRequest(
        uid=user.uid,
        first_name=user.first_name,
        last_name=user.last_name,
        email=user.email
    ) for user in users]
