from fastapi import APIRouter
from ..utils.logger import logger

router = APIRouter()

@router.get("/recommendations/{user_id}")
def get_recommendations(user_id: str):
    logger.info(f"[get_recommendations] Fetching recommendations for user {user_id}")
    # TODO: Integrate ML recommendation logic
    return {"recommendations": ["Gift Card", "Book", "Headphones"]}
