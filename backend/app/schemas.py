from pydantic import BaseModel
from typing import Optional, List

class UserProfileBase(BaseModel):
    tshirt_size: Optional[str] = None
    gender: Optional[str] = None
    shoe_size: Optional[str] = None
    pants_jeans_size: Optional[str] = None
    dress_size: Optional[str] = None
    shirt_size: Optional[str] = None
    jacket_size: Optional[str] = None
    hat_size: Optional[str] = None
    glove_size: Optional[str] = None
    belt_size: Optional[str] = None
    bra_size: Optional[str] = None
    ring_size: Optional[str] = None
    sock_size: Optional[str] = None
    height: Optional[str] = None
    notes: Optional[str] = None
    interests: Optional[List[str]] = None
    date_of_birth: Optional[str] = None  # ISO format string

class UserProfileCreate(UserProfileBase):
    uid: str

class UserProfileUpdate(UserProfileBase):
    pass

class UserProfileInDB(UserProfileBase):
    uid: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[str] = None
    gender: Optional[str] = None

    class Config:
        orm_mode = True
