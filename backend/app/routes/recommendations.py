from fastapi import APIRouter

router = APIRouter()

@router.get("/recommendations/{user_id}")
def get_recommendations(user_id: str):
    # TODO: Integrate ML recommendation logic
    return {"recommendations": ["Gift Card", "Book", "Headphones"]}
