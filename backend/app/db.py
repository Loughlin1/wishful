from .models import WishList, WishItem


# In-memory store (replace with DB/Firebase in production)
wishlists = {
    1: WishList(
        id=1,
        owner="Demo User",
        owner_id="demo_uid",
        items=[
            WishItem(id=1, name="Book", reserved=False),
            WishItem(id=2, name="Headphones", reserved=True, reserved_by="Alice"),
        ],
        shared_with=["demo_friend_uid"],
    )
}


share_tokens = {}
