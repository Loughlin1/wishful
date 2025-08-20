from sqlalchemy.orm import Session
from .models import UserDB, WishListDB, WishItemDB, SharedWithDB
from ..models import WishListRequest, WishItemRequest, UserRequest


def get_user_by_uid(db: Session, uid: str):
    return db.query(UserDB).filter(UserDB.uid == uid).first()

def create_user(db: Session, user: UserRequest) -> UserDB:
    user_db = UserDB(
        uid=user.uid,
        first_name=user.first_name,
        last_name=user.last_name,
        email=user.email
    )
    db.add(user_db)
    db.commit()
    db.refresh(user_db)
    return user_db

def get_wishlist_by_id(db: Session, wishlist_id: int) -> WishListDB:
    return db.query(WishListDB).filter(WishListDB.id == wishlist_id).first()

def get_wishlists_for_user(db: Session, user_id: str) -> list[WishListDB]:
    return db.query(WishListDB).filter(WishListDB.owner_id == user_id).all()

def create_wishlist(db: Session, wishlist_db: WishListDB) -> WishListDB:
    db.add(wishlist_db)
    db.commit()
    db.refresh(wishlist_db)
    return wishlist_db

def get_items_for_wishlist(db: Session, wishlist_id: int) -> list[WishItemDB]:
    return db.query(WishItemDB).filter(WishItemDB.wishlist_id == wishlist_id).all()

def add_item_to_wishlist(db: Session, item_db: WishItemDB) -> WishItemDB:
    db.add(item_db)
    db.commit()
    db.refresh(item_db)
    return item_db

def share_wishlist_with_user(db: Session, wishlist_id: int, user_id: str):
    shared = SharedWithDB(wishlist_id=wishlist_id, user_id=user_id)
    db.add(shared)
    db.commit()
    return shared

def get_shared_wishlists_for_user(db: Session, user_id: str):
    db_wishlists = db.query(WishListDB).join(
        SharedWithDB
    ).filter(SharedWithDB.user_id == user_id).all()
    result = []
    for db_wishlist in db_wishlists:
        items = [WishItemRequest(
            id=item.id,
            name=item.name,
            reserved=item.reserved,
            reserved_by=item.reserved_by
        ) for item in db_wishlist.items]
        shared_with = [sw.user_id for sw in db_wishlist.shared_with]
        result.append(WishListRequest(
            id=db_wishlist.id,
            name=db_wishlist.name,
            owner_id=db_wishlist.owner_id,
            owner_first_name=db_wishlist.owner_user.first_name,
            owner_last_name=db_wishlist.owner_user.last_name,
            items=items,
            shared_with=shared_with,
            tag=db_wishlist.tag
        ))
    return result
