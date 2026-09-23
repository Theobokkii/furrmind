import uuid
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple, Dict, Any

import bcrypt
from jose import jwt, JWTError

from app.config import settings
from app.models.schemas import (
    RegisterRequest,
    UserProfile,
    TokenResponse,
)
from app.services.email_service import (
    generate_otp,
    send_verification_email,
    send_password_reset_email,
)
from app.services.firebase_service import get_db, get_auth

logger = logging.getLogger(__name__)

# Fallback in-memory stores for testing or when Firestore/Firebase credentials aren't active yet
_mock_users: Dict[str, Dict[str, Any]] = {}
_mock_otps: Dict[str, Dict[str, Any]] = {}
_mock_login_attempts: Dict[str, Dict[str, Any]] = {}

MAX_LOGIN_ATTEMPTS = 5
LOCKOUT_MINUTES = 15


# --- Password Helpers ---

def hash_password(password: str) -> str:
    """Hash password using bcrypt."""
    pw_bytes = password.encode("utf-8")[:72]
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pw_bytes, salt).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against bcrypt hash."""
    try:
        pw_bytes = plain_password.encode("utf-8")[:72]
        hash_bytes = hashed_password.encode("utf-8")
        return bcrypt.checkpw(pw_bytes, hash_bytes)
    except Exception as e:
        logger.error(f"Password verification error: {e}")
        return False


# --- Token Helpers ---

def create_access_token(user_id: str, email: str, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token."""
    expire = datetime.now(timezone.utc) + (
        expires_delta if expires_delta else timedelta(minutes=settings.access_token_expire_minutes)
    )
    payload = {
        "sub": user_id,
        "email": email,
        "type": "access",
        "exp": expire,
        "iat": datetime.now(timezone.utc),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_refresh_token(user_id: str, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT refresh token."""
    expire = datetime.now(timezone.utc) + (
        expires_delta if expires_delta else timedelta(days=settings.refresh_token_expire_days)
    )
    payload = {
        "sub": user_id,
        "type": "refresh",
        "exp": expire,
        "iat": datetime.now(timezone.utc),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_token(token: str, expected_type: str = "access") -> dict:
    """Decode and validate JWT token claims."""
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
        if payload.get("type") != expected_type:
            raise ValueError(f"Invalid token type: expected {expected_type}")
        return payload
    except JWTError as e:
        raise ValueError(f"Token invalid or expired: {e}")


# --- Rate Limiting Helpers ---

def _check_rate_limit(email: str) -> Tuple[bool, Optional[str]]:
    """Check if user is temporarily locked out due to excessive failed logins."""
    now = datetime.now(timezone.utc)
    db = get_db()
    
    if db:
        try:
            doc_ref = db.collection("login_attempts").document(email)
            doc = doc_ref.get()
            if doc.exists:
                data = doc.to_dict()
                locked_until = data.get("locked_until")
                if locked_until and datetime.fromisoformat(locked_until) > now:
                    remaining_mins = int((datetime.fromisoformat(locked_until) - now).total_seconds() / 60) + 1
                    return False, f"Account temporarily locked due to too many failed attempts. Try again in {remaining_mins} minutes."
        except Exception as e:
            logger.warning(f"Error checking Firestore rate limit: {e}")
    else:
        attempt_info = _mock_login_attempts.get(email)
        if attempt_info:
            locked_until = attempt_info.get("locked_until")
            if locked_until and locked_until > now:
                remaining_mins = int((locked_until - now).total_seconds() / 60) + 1
                return False, f"Account temporarily locked due to too many failed attempts. Try again in {remaining_mins} minutes."

    return True, None


def _record_failed_login(email: str):
    """Record a failed login attempt."""
    now = datetime.now(timezone.utc)
    db = get_db()

    if db:
        try:
            doc_ref = db.collection("login_attempts").document(email)
            doc = doc_ref.get()
            attempts = 1
            if doc.exists:
                data = doc.to_dict()
                attempts = data.get("attempts", 0) + 1
            
            payload = {"attempts": attempts, "updated_at": now.isoformat()}
            if attempts >= MAX_LOGIN_ATTEMPTS:
                payload["locked_until"] = (now + timedelta(minutes=LOCKOUT_MINUTES)).isoformat()
            doc_ref.set(payload, merge=True)
        except Exception as e:
            logger.warning(f"Error recording Firestore failed login: {e}")
    else:
        info = _mock_login_attempts.get(email, {"attempts": 0})
        attempts = info.get("attempts", 0) + 1
        locked_until = None
        if attempts >= MAX_LOGIN_ATTEMPTS:
            locked_until = now + timedelta(minutes=LOCKOUT_MINUTES)
        _mock_login_attempts[email] = {
            "attempts": attempts,
            "locked_until": locked_until,
            "updated_at": now,
        }


def _reset_login_attempts(email: str):
    """Reset failed login attempts counter."""
    db = get_db()
    if db:
        try:
            db.collection("login_attempts").document(email).delete()
        except Exception as e:
            logger.warning(f"Error resetting Firestore login attempts: {e}")
    else:
        _mock_login_attempts.pop(email, None)


# --- User Store Helpers ---

def get_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    """Fetch user record by email from Firestore or in-memory fallback."""
    db = get_db()
    if db:
        try:
            users_ref = db.collection("users")
            query = users_ref.where("email", "==", email).limit(1).stream()
            for doc in query:
                data = doc.to_dict()
                data["id"] = doc.id
                return data
        except Exception as e:
            logger.warning(f"Firestore get_user_by_email error: {e}")
            
    # Fallback to mock store
    for uid, user in _mock_users.items():
        if user.get("email") == email:
            return user
    return None


def get_user_by_id(user_id: str) -> Optional[UserProfile]:
    """Fetch user profile by user_id."""
    db = get_db()
    if db:
        try:
            doc = db.collection("users").document(user_id).get()
            if doc.exists:
                data = doc.to_dict()
                created_at = data.get("created_at")
                if isinstance(created_at, str):
                    created_at = datetime.fromisoformat(created_at)
                return UserProfile(
                    id=doc.id,
                    email=data.get("email"),
                    display_name=data.get("display_name"),
                    photo_url=data.get("photo_url"),
                    is_email_verified=data.get("is_email_verified", False),
                    created_at=created_at,
                )
        except Exception as e:
            logger.warning(f"Firestore get_user_by_id error: {e}")

    user = _mock_users.get(user_id)
    if user:
        return UserProfile(
            id=user["id"],
            email=user["email"],
            display_name=user.get("display_name"),
            photo_url=user.get("photo_url"),
            is_email_verified=user.get("is_email_verified", False),
            created_at=user.get("created_at"),
        )
    return None


# --- OTP Helpers ---

def _store_otp(email: str, code: str, purpose: str):
    """Store OTP with expiry time."""
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(minutes=settings.otp_expire_minutes)
    payload = {
        "email": email,
        "code": code,
        "purpose": purpose,
        "expires_at": expires_at.isoformat(),
        "created_at": now.isoformat(),
    }
    
    db = get_db()
    if db:
        try:
            db.collection("otp_codes").document(f"{email}_{purpose}").set(payload)
            return
        except Exception as e:
            logger.warning(f"Firestore store OTP error: {e}")

    _mock_otps[f"{email}_{purpose}"] = {
        "email": email,
        "code": code,
        "purpose": purpose,
        "expires_at": expires_at,
        "created_at": now,
    }


def _verify_and_consume_otp(email: str, code: str, purpose: str) -> bool:
    """Verify OTP code and delete on success."""
    now = datetime.now(timezone.utc)
    db = get_db()
    key = f"{email}_{purpose}"

    if db:
        try:
            doc_ref = db.collection("otp_codes").document(key)
            doc = doc_ref.get()
            if not doc.exists:
                return False
            data = doc.to_dict()
            stored_code = data.get("code")
            expires_at = datetime.fromisoformat(data.get("expires_at"))
            if stored_code == code and expires_at > now:
                doc_ref.delete()
                return True
            return False
        except Exception as e:
            logger.warning(f"Firestore verify OTP error: {e}")

    record = _mock_otps.get(key)
    if not record:
        return False
    
    expires_at = record["expires_at"]
    if isinstance(expires_at, str):
        expires_at = datetime.fromisoformat(expires_at)

    if record["code"] == code and expires_at > now:
        _mock_otps.pop(key, None)
        return True
    return False


# --- Core Auth Business Logic ---

def register_user(req: RegisterRequest) -> Tuple[UserProfile, str]:
    """Register a new user and generate verification OTP."""
    existing_user = get_user_by_email(req.email)
    if existing_user:
        raise ValueError("Email is already registered")

    user_id = str(uuid.uuid4())
    password_hash = hash_password(req.password)
    now = datetime.now(timezone.utc)

    # Optional: Register to Firebase Auth if live credentials are active
    fb_auth = get_auth()
    try:
        fb_auth.create_user(
            uid=user_id,
            email=req.email,
            password=req.password,
            display_name=req.display_name or "",
        )
    except Exception as e:
        logger.debug(f"Firebase Auth user creation skipped/failed: {e}")

    user_record = {
        "id": user_id,
        "email": req.email,
        "display_name": req.display_name,
        "password_hash": password_hash,
        "is_email_verified": False,
        "created_at": now.isoformat(),
        "photo_url": None,
    }

    db = get_db()
    if db:
        try:
            db.collection("users").document(user_id).set(user_record)
        except Exception as e:
            logger.warning(f"Failed to persist user in Firestore: {e}")

    _mock_users[user_id] = {**user_record, "created_at": now}

    # Generate & send OTP
    otp = generate_otp()
    _store_otp(req.email, otp, "verify_email")
    send_verification_email(req.email, otp)

    profile = UserProfile(
        id=user_id,
        email=req.email,
        display_name=req.display_name,
        is_email_verified=False,
        created_at=now,
    )
    return profile, otp


def verify_email(email: str, code: str) -> bool:
    """Verify user's email with OTP."""
    if not _verify_and_consume_otp(email, code, "verify_email"):
        return False

    db = get_db()
    if db:
        try:
            users_ref = db.collection("users")
            query = users_ref.where("email", "==", email).limit(1).stream()
            for doc in query:
                doc.reference.update({"is_email_verified": True})
        except Exception as e:
            logger.warning(f"Failed to update email verification in Firestore: {e}")

    for uid, user in _mock_users.items():
        if user.get("email") == email:
            user["is_email_verified"] = True

    return True


def resend_verification(email: str) -> bool:
    """Resend email verification OTP."""
    user = get_user_by_email(email)
    if not user:
        raise ValueError("User with this email not found")
    if user.get("is_email_verified"):
        raise ValueError("Email is already verified")

    otp = generate_otp()
    _store_otp(email, otp, "verify_email")
    send_verification_email(email, otp)
    return True


def authenticate_user(email: str, password: str) -> Tuple[UserProfile, TokenResponse]:
    """Authenticate user credentials and issue tokens with lockout protection."""
    is_allowed, lock_msg = _check_rate_limit(email)
    if not is_allowed:
        raise PermissionError(lock_msg)

    user = get_user_by_email(email)
    if not user or not verify_password(password, user.get("password_hash", "")):
        _record_failed_login(email)
        raise ValueError("Invalid email or password")

    _reset_login_attempts(email)

    user_id = user["id"]
    access_token = create_access_token(user_id=user_id, email=email)
    refresh_token = create_refresh_token(user_id=user_id)

    profile = UserProfile(
        id=user_id,
        email=user["email"],
        display_name=user.get("display_name"),
        photo_url=user.get("photo_url"),
        is_email_verified=user.get("is_email_verified", False),
    )

    tokens = TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=settings.access_token_expire_minutes * 60,
    )
    return profile, tokens


def refresh_user_tokens(refresh_token: str) -> TokenResponse:
    """Validate refresh token and issue new token pair."""
    payload = decode_token(refresh_token, expected_type="refresh")
    user_id = payload.get("sub")
    if not user_id:
        raise ValueError("Invalid token subject")

    profile = get_user_by_id(user_id)
    if not profile:
        raise ValueError("User not found")

    new_access_token = create_access_token(user_id=user_id, email=profile.email)
    new_refresh_token = create_refresh_token(user_id=user_id)

    return TokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        token_type="bearer",
        expires_in=settings.access_token_expire_minutes * 60,
    )


def request_password_reset(email: str) -> bool:
    """Initiate password reset request with OTP."""
    user = get_user_by_email(email)
    if not user:
        # Avoid user enumeration by returning True silently
        return True

    otp = generate_otp()
    _store_otp(email, otp, "reset_password")
    send_password_reset_email(email, otp)
    return True


def reset_user_password(email: str, code: str, new_password: str) -> bool:
    """Reset password after OTP verification."""
    if not _verify_and_consume_otp(email, code, "reset_password"):
        raise ValueError("Invalid or expired reset code")

    user = get_user_by_email(email)
    if not user:
        raise ValueError("User not found")

    new_hash = hash_password(new_password)
    user_id = user["id"]

    db = get_db()
    if db:
        try:
            db.collection("users").document(user_id).update({"password_hash": new_hash})
        except Exception as e:
            logger.warning(f"Failed to update password in Firestore: {e}")

    if user_id in _mock_users:
        _mock_users[user_id]["password_hash"] = new_hash

    return True
