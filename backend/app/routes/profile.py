from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from ..schemas import UserProfileCreate, UserProfileUpdate, UserProfileInDB
from ..db.database import SessionLocal
from ..db.crud import get_user_profile, create_user_profile, update_user_profile
from ..db.models import UserDB
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
    profile_dict = dict(db_profile.__dict__)
    interests_val = profile_dict.pop('interests', None)
    user = db.query(UserDB).filter(UserDB.uid == profile.uid).first()
    return UserProfileInDB(
        **profile_dict,
        interests=interests_val.split(',') if interests_val else [],
        first_name=getattr(user, "first_name", None) if user else None,
        last_name=getattr(user, "last_name", None) if user else None,
        email=getattr(user, "email", None) if user else None,
        gender=getattr(user, "gender", None) if user else None,
    )

@router.put("/profile/{uid}", response_model=UserProfileInDB)
def update_profile(uid: str, profile: UserProfileUpdate, db: Session = Depends(get_db)):
    db_profile = update_user_profile(db, uid, profile)
    if not db_profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    profile_dict = dict(db_profile.__dict__)
    interests_val = profile_dict.pop('interests', None)
    user = db.query(UserDB).filter(UserDB.uid == uid).first()
    # Remove gender from profile_dict to avoid duplicate key error
    profile_dict.pop('gender', None)
    return UserProfileInDB(
        **profile_dict,
        interests=interests_val.split(',') if interests_val else [],
        first_name=getattr(user, "first_name", None) if user else None,
        last_name=getattr(user, "last_name", None) if user else None,
        email=getattr(user, "email", None) if user else None,
        date_of_birth=getattr(user, "date_of_birth", None) if user else None,
        gender=getattr(user, "gender", None) if user else None,
    )

@router.get("/profile/{uid}", response_model=UserProfileInDB)
def get_profile(uid: str, db: Session = Depends(get_db)):
    db_profile = get_user_profile(db, uid)
    if not db_profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    profile_dict = dict(db_profile.__dict__)
    interests_val = profile_dict.pop('interests', None)
    user = db.query(UserDB).filter(UserDB.uid == uid).first()
    return UserProfileInDB(
        **profile_dict,
        interests=interests_val.split(',') if interests_val else [],
        first_name=getattr(user, "first_name", None) if user else None,
        last_name=getattr(user, "last_name", None) if user else None,
        email=getattr(user, "email", None) if user else None,
        date_of_birth=getattr(user, "date_of_birth", None) if user else None,
        gender=getattr(user, "gender", None) if user else None,
    )
