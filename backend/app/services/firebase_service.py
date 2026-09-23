import os
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from firebase_admin import auth as firebase_auth
from app.config import settings

# Global Firestore client
_db = None
_initialized = False

def init_firebase():
    """Initialize Firebase Admin SDK."""
    global _db, _initialized
    if _initialized:
        return
    _initialized = True
    
    # Avoid re-initialization if already initialized
    if not firebase_admin._apps:
        cred_path = settings.firebase_credentials_path
        
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            print(f"Firebase initialized with credentials from {cred_path}")
        elif os.environ.get("GOOGLE_APPLICATION_CREDENTIALS") and os.path.exists(os.environ["GOOGLE_APPLICATION_CREDENTIALS"]):
            try:
                firebase_admin.initialize_app()
                print("Firebase initialized with default credentials.")
            except Exception as e:
                print(f"Failed to initialize Firebase with default credentials: {e}")
        else:
            print(f"INFO: Firebase credentials file not found at '{cred_path}'. Operating in local fallback mode.")
                
    # Initialize Firestore client
    try:
        if _db is None and firebase_admin._apps:
            _db = firestore.client()
    except Exception as e:
        print(f"Failed to initialize Firestore client: {e}")

def get_db():
    """Get Firestore database instance."""
    global _db
    if _db is None:
        init_firebase()
    return _db

def get_auth():
    """Get Firebase Auth module."""
    return firebase_auth
