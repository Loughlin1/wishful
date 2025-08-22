from sqlalchemy.orm import Session
from sqlalchemy import or_
from .models import UserDB, WishListDB, WishItemDB
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
    return db.query(WishListDB).filter(
        or_(WishListDB.owner_id == user_id, WishListDB.shared_with.any(UserDB.uid == user_id))
    ).all()

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
    wishlist = db.query(WishListDB).filter(WishListDB.id == wishlist_id).first()
    user = db.query(UserDB).filter(UserDB.uid == user_id).first()
    if wishlist and user and user not in wishlist.shared_with:
        wishlist.shared_with.append(user)
        db.commit()
    return wishlist

def get_shared_wishlists_for_user(db: Session, user_id: str):
    user = db.query(UserDB).filter(UserDB.uid == user_id).first()
    if not user:
        return []
    result = []
    for db_wishlist in user.shared_wishlists:
        items = [WishItemRequest(
            id=item.id,
            name=item.name,
            reserved=item.reserved,
            reserved_by=item.reserved_by,
            link=item.link
        ) for item in db_wishlist.items]
        shared_with = [u.uid for u in db_wishlist.shared_with]
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

def get_shared_user_emails_for_wishlist(db: Session, wishlist_id: int) -> list[str]:
    wishlist = db.query(WishListDB).filter(WishListDB.id == wishlist_id).first()
    if not wishlist:
        return []
    return [user.email for user in wishlist.shared_with]


def unshare_wishlist_with_user(db: Session, wishlist_id: int, email: str):
    wishlist = db.query(WishListDB).filter(WishListDB.id == wishlist_id).first()
    user = db.query(UserDB).filter(UserDB.email == email).first()
    if wishlist and user and user in wishlist.shared_with:
        wishlist.shared_with.remove(user)
        db.commit()
    return wishlist

