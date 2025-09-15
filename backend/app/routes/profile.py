from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from ..schemas import UserProfileCreate, UserProfileUpdate, UserProfileInDB
from ..db.database import SessionLocal
from ..db.crud import get_user_profile, create_user_profile, update_user_profile
from ..auth import verify_token

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/profile", response_model=UserProfileInDB)
def create_profile(profile: UserProfileCreate, db: Session = Depends(get_db)):
    if get_user_profile(db, profile.uid):
        raise HTTPException(status_code=400, detail="Profile already exists")
    db_profile = create_user_profile(db, profile)
    interests_val = db_profile.__dict__.get('interests')
    return UserProfileInDB(
        **db_profile.__dict__,
        interests=interests_val.split(',') if interests_val else []
    )

@router.put("/profile/{uid}", response_model=UserProfileInDB)
def update_profile(uid: str, profile: UserProfileUpdate, db: Session = Depends(get_db)):
    db_profile = update_user_profile(db, uid, profile)
    if not db_profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    interests_val = db_profile.__dict__.get('interests')
    return UserProfileInDB(
        **db_profile.__dict__,
        interests=interests_val.split(',') if interests_val else []
    )
