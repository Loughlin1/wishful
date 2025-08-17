import firebase_admin
from firebase_admin import auth, credentials
from fastapi import HTTPException, Request, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import os
from dotenv import load_dotenv

load_dotenv()
cred_path = os.environ.get('FIREBASE_CREDENTIALS')
cred = credentials.Certificate(cred_path)
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

security = HTTPBearer()

def verify_token(request: Request, credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        request.state.user = decoded_token
        return decoded_token
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")
