import os
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from firebase_admin import auth as firebase_auth
from app.config import settings

# Global Firestore client
_db = None

def init_firebase():
    """Initialize Firebase Admin SDK."""
    global _db
    
    # Avoid re-initialization if already initialized
    if not firebase_admin._apps:
        cred_path = settings.firebase_credentials_path
        
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            print(f"Firebase initialized with credentials from {cred_path}")
        else:
            print(f"WARNING: Firebase credentials not found at {cred_path}. Using default.")
            try:
                firebase_admin.initialize_app()
            except Exception as e:
                print(f"Failed to initialize Firebase without credentials: {e}")
                
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
