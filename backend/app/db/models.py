from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Text
from sqlalchemy.orm import relationship, declarative_base

Base = declarative_base()

class UserDB(Base):
    __tablename__ = 'users'
    uid = Column(String, primary_key=True, index=True)
    first_name = Column(String)
    last_name = Column(String)
    email = Column(String, unique=True, index=True)
    wishlists = relationship('WishListDB', back_populates='owner_user')

class WishListDB(Base):
    __tablename__ = 'wishlists'
    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(String, ForeignKey('users.uid'))
    name = Column(String, unique=True, nullable=False)
    tag = Column(String)
    items = relationship('WishItemDB', back_populates='wishlist', cascade='all, delete-orphan')
    shared_with = relationship('SharedWithDB', back_populates='wishlist', cascade='all, delete-orphan')
    owner_user = relationship('UserDB', back_populates='wishlists')

class WishItemDB(Base):
    __tablename__ = 'wishlist_items'
    id = Column(Integer, primary_key=True, index=True)
    wishlist_id = Column(Integer, ForeignKey('wishlists.id'))
    name = Column(String)
    reserved = Column(Boolean, default=False)
    reserved_by = Column(String, nullable=True)
    wishlist = relationship('WishListDB', back_populates='items')

class SharedWithDB(Base):
    __tablename__ = 'shared_with'
    wishlist_id = Column(Integer, ForeignKey('wishlists.id'), primary_key=True)
    user_id = Column(String, primary_key=True)
    wishlist = relationship('WishListDB', back_populates='shared_with')
