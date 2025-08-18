from pydantic import BaseModel
from typing import List, Optional
from enum import Enum

class TagEnum(str, Enum):
    birthday = "Birthday"
    xmas = "Xmas"
    other = "Other"


class WishItem(BaseModel):
    id: int
    name: str
    reserved: bool = False
    reserved_by: Optional[str] = None


class WishList(BaseModel):
    id: int
    owner: str
    owner_id: str
    items: List[WishItem]
    shared_with: Optional[List[str]] = []
    tag: Optional[TagEnum] = None


class WishListCreate(BaseModel):
    id: int
    owner: str
    items: List[WishItem]
    shared_with: Optional[List[str]] = []
    tag: Optional[TagEnum] = None


# User model for registration
class User(BaseModel):
    uid: str
    first_name: str
    last_name: str
    email: str
