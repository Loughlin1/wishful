from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import router as wishful_router

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
