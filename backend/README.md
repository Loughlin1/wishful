# Wishful Backend (Python)

A FastAPI backend for ML recommendations, RESTful API, and Firebase integration.

## Structure
- Built with FastAPI
- ML recommendation engine (scikit-learn, pandas)
- Firebase Admin SDK for user and wish list management
- RESTful endpoints for frontend

## Getting Started
1. Create and activate virtual environment:
   ```
   cd backend
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```
2. Run the server:
   ```
   uvicorn main:app --reload
   ```

## Folder Structure
- `app/` - Main API code
- `ml/` - ML recommendation code
- `tests/` - Unit tests

## Environment
- Use `.env` for secrets and config

---
