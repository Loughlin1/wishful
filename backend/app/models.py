from pydantic import BaseModel
from typing import List, Optional

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
