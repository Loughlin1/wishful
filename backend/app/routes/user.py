from fastapi import APIRouter, HTTPException, Depends, Request
from ..models import User
from ..db import users
from ..auth import verify_token

router = APIRouter()

@router.post("/register", response_model=User)
def register_user(user: User, request: Request):
    if user.uid in users:
        raise HTTPException(status_code=400, detail="User already exists")
    users[user.uid] = user
    return user
