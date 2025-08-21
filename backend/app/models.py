from pydantic import BaseModel
from typing import List, Optional
from enum import Enum

class TagEnum(str, Enum):
    birthday = "Birthday"
    xmas = "Xmas"
    other = "Other"



class WishItemRequest(BaseModel):
    id: int
    name: str
    reserved: bool = False
    reserved_by: Optional[str] = None
    link: Optional[str] = None


class WishListRequest(BaseModel):
    id: int
    name: str
    owner_id: str
    owner_first_name: str
    owner_last_name: str
    items: List[WishItemRequest]
    shared_with: Optional[List[str]] = []
    tag: Optional[TagEnum] = None


# User model for registration
class UserRequest(BaseModel):
    uid: str
    first_name: str
    last_name: str
    email: str


class EmailRequest(BaseModel):
    email: str


class CreateGroupRequest(BaseModel):
    name: str
    users: list[str]

