from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes.wishlist import router as wishlist_router
from .routes.wishlist_items import router as wishlist_items_router
from .routes.sharing import router as sharing_router
from .routes.recommendations import router as recommendations_router

# User registration router
from .routes.user import router as user_router

app = FastAPI()

# Allow CORS for all origins (for development)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API routes
app.include_router(wishlist_router)
app.include_router(wishlist_items_router)
app.include_router(sharing_router)
app.include_router(recommendations_router)
app.include_router(user_router)
