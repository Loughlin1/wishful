from fastapi import APIRouter, HTTPException, Depends, Request
from ..utils.logger import logger
from sqlalchemy.orm import Session
from ..models import UserRequest
from ..db.database import SessionLocal
from ..db.crud import get_user_by_uid, create_user
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
