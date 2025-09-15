from sqlalchemy.orm import Session
from sqlalchemy import or_
from .models import UserDB, WishListDB, WishItemDB
from .models import UserDB, WishListDB, WishItemDB, UserProfileDB
from ..models import WishListRequest, WishItemRequest, UserRequest
from ..models import WishListRequest, WishItemRequest, UserRequest
from ..schemas import UserProfileCreate, UserProfileUpdate


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

def get_user_profile(db: Session, uid: str):
    return db.query(UserProfileDB).filter(UserProfileDB.uid == uid).first()

def create_user_profile(db: Session, profile: UserProfileCreate):
    db_profile = UserProfileDB(
        uid=profile.uid,
        tshirt_size=profile.tshirt_size,
        shoe_size=profile.shoe_size,
        pants_jeans_size=profile.pants_jeans_size,
        dress_size=profile.dress_size,
        shirt_size=profile.shirt_size,
        jacket_size=profile.jacket_size,
        hat_size=profile.hat_size,
        glove_size=profile.glove_size,
        belt_size=profile.belt_size,
        bra_size=profile.bra_size,
        ring_size=profile.ring_size,
        sock_size=profile.sock_size,
        height=profile.height,
        notes=profile.notes,
        interests=','.join(profile.interests) if profile.interests else None,
    )
    db.add(db_profile)
    db.commit()
    db.refresh(db_profile)
    return db_profile

def update_user_profile(db: Session, uid: str, profile: UserProfileUpdate):
    db_profile = db.query(UserProfileDB).filter(UserProfileDB.uid == uid).first()
    if not db_profile:
        return None
    for field, value in profile.dict(exclude_unset=True).items():
        if field == 'interests' and value is not None:
            setattr(db_profile, field, ','.join(value))
        else:
            setattr(db_profile, field, value)
    db.commit()
    db.refresh(db_profile)
    return db_profile


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
