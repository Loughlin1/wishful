# Wishful AI Coding Agent Instructions

Welcome to the Wishful codebase! This project is a full-stack wishlist platform with a FastAPI backend and a Flutter frontend. Follow these guidelines to be immediately productive as an AI coding agent.

## Architecture Overview
- **Backend:** Python (FastAPI), located in `backend/app/`. Handles RESTful API, ML recommendations, and Firebase integration.
- **Frontend:** Flutter (Dart), located in `frontend/lib/`. Connects to backend for data and recommendations, uses Firebase for auth and storage.
- **Data Flow:** Frontend communicates with backend via HTTP API. Backend may use ML (see `backend/ml/`) and Firebase Admin SDK for user/wishlist management.

## Key Workflows
- **Backend Development:**
  - Create a Python virtual environment in `backend/` and install dependencies from `requirements.txt`.
  - Run backend server with `uvicorn main:app --reload` or `make backend`.
  - Database models and CRUD: see `backend/app/db/`.
  - API routes: see `backend/app/routes/`.
  - ML logic: see `backend/ml/`.
  - Use `.env` for secrets/config.
- **Frontend Development:**
  - Run `flutter pub get` in `frontend/`.
  - Start app with `flutter run` (mobile) or `flutter run -d chrome` (web).
  - Main app code: `frontend/lib/`.
  - Firebase config: `frontend/lib/firebase_options.dart`.

## Conventions & Patterns
- **Backend:**
  - Use Pydantic models for schemas (`backend/app/schemas.py`).
  - API endpoints are organized by resource in `routes/`.
  - Database access via SQLAlchemy in `db/`.
  - ML code is isolated in `ml/`.
  - Alembic for migrations (`backend/alembic/`).
- **Frontend:**
  - State managed via StatefulWidgets and controllers.
  - API calls abstracted in `services/` (e.g., `user_profile_api_service.dart`).
  - UI components in `widgets/`.
  - Models in `models/`.
  - Screens in `screens/`.

## Integration Points
- **Firebase:** Used for authentication (frontend) and admin operations (backend).
- **ML Recommendations:** Backend exposes endpoints for personalized suggestions.
- **Cross-platform:** Flutter supports web, mobile, desktop; backend is platform-agnostic.

## Examples
- To fetch a user profile: Frontend calls backend API via service in `frontend/lib/services/`, backend handles via route in `backend/app/routes/profile.py`.
- To add a wishlist item: Frontend form posts to backend, backend updates DB via CRUD in `db/`.

## Tips for AI Agents
- Always check for existing abstractions in `services/` (frontend) and `db/` (backend) before adding new logic.
- Follow folder conventions for new features (e.g., new API route in `routes/`, new screen in `screens/`).
- Use provided Makefile targets for common tasks.
- Reference README files in root, backend, and frontend for setup and workflow details.

---
For questions or unclear patterns, ask for clarification or review related files before making changes.
