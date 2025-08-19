# Wishful

Wishful is a full-stack application designed to help users create, manage, and share wishlists. The project consists of a Python backend (FastAPI) and a Flutter frontend, providing a seamless experience across web and mobile platforms.

## Features

- User authentication and registration
- Create, edit, and delete wishlists
- Add, update, and remove wishlist items
- Share wishlists with other users
- Personalized recommendations
- Cross-platform support (Web, Android, iOS, macOS, Windows, Linux)

## Project Structure

```
Wishful/
├── backend/         # Python FastAPI backend
│   ├── app/
│   │   ├── db/      # Database models and CRUD operations
│   │   ├── routes/  # API route definitions
│   │   ├── ...      # Other backend modules
│   ├── main.py      # Backend entry point
│   └── requirements.txt
├── frontend/        # Flutter frontend
│   ├── lib/         # Dart source code
│   ├── android/     # Android-specific files
│   ├── ios/         # iOS-specific files
│   ├── web/         # Web-specific files
│   └── ...
└── README.md        # Project summary
```

## Backend
- **Framework:** FastAPI
- **Database:** SQLite (default, can be changed)
- **Location:** `backend/app/`
- **Run:**
  ```sh
make backend
  ```

## Frontend
- **Framework:** Flutter
- **Location:** `frontend/`
- **Run:**
  ```sh
make frontend
  ```

## Setup
1. **Clone the repository:**
   ```sh
   git clone <repo-url>
   cd Wishful
   ```
2. **Backend:**
   - Create a virtual environment and install dependencies:
     ```sh
     cd backend
     python3 -m venv venv
     source venv/bin/activate
     pip install -r requirements.txt
     ```
   - Start the backend server:
     ```sh
     uvicorn app.main:app --reload
     ```
3. **Frontend:**
   - Install Flutter dependencies:
     ```sh
     cd frontend
     flutter pub get
     ```
   - Run the app on your desired platform:
     ```sh
     flutter run
     ```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
