from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes.wishlist import router as wishful_router
from .routes.sharing import router as sharing_router
from .routes.recommendations import router as recommendations_router

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
app.include_router(wishful_router)
app.include_router(sharing_router)
app.include_router(recommendations_router)
