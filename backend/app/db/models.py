
from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Text, Table
from sqlalchemy.orm import relationship, declarative_base


Base = declarative_base()

# Association table for wishlists shared with users
wishlist_shared_with = Table(
    'shared_with',
    Base.metadata,
    Column('wishlist_id', Integer, ForeignKey('wishlists.id'), primary_key=True),
    Column('user_id', String, ForeignKey('users.uid'), primary_key=True)
)


class UserDB(Base):
    __tablename__ = 'users'
    uid = Column(String, primary_key=True, index=True)
    first_name = Column(String)
    last_name = Column(String)
    email = Column(String, unique=True, index=True)
    wishlists = relationship('WishListDB', back_populates='owner_user')
    shared_wishlists = relationship(
        'WishListDB',
        secondary=wishlist_shared_with,
        back_populates='shared_with'
    )


class WishListDB(Base):
    __tablename__ = 'wishlists'
    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(String, ForeignKey('users.uid'))
    name = Column(String, unique=True, nullable=False)
    tag = Column(String)
    items = relationship('WishItemDB', back_populates='wishlist', cascade='all, delete-orphan')
    shared_with = relationship(
        'UserDB',
        secondary=wishlist_shared_with,
        back_populates='shared_wishlists'
    )
    owner_user = relationship('UserDB', back_populates='wishlists')

class WishItemDB(Base):
    __tablename__ = 'wishlist_items'
    id = Column(Integer, primary_key=True, index=True)
    wishlist_id = Column(Integer, ForeignKey('wishlists.id'))
    name = Column(String)
    reserved = Column(Boolean, default=False)
    reserved_by = Column(String, nullable=True)
    link = Column(String, nullable=True)
    wishlist = relationship('WishListDB', back_populates='items')


# Removed SharedWithDB mapped class; now using association table for many-to-many

class GroupDB(Base):
    __tablename__ = 'groups'
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    owner_id = Column(String, ForeignKey('users.uid'))
    members = relationship('GroupMemberDB', back_populates='group', cascade='all, delete-orphan')

class GroupMemberDB(Base):
    __tablename__ = 'group_members'
    group_id = Column(Integer, ForeignKey('groups.id'), primary_key=True)
    user_id = Column(String, ForeignKey('users.uid'), primary_key=True)
    group = relationship('GroupDB', back_populates='members')

class SharedWithGroupDB(Base):
    __tablename__ = 'shared_with_group'
    wishlist_id = Column(Integer, ForeignKey('wishlists.id'), primary_key=True)
    group_id = Column(Integer, ForeignKey('groups.id'), primary_key=True)