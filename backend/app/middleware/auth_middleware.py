import logging
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.services.auth_service import decode_token, get_user_by_id
from app.models.schemas import UserProfile

logger = logging.getLogger(__name__)

_bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme),
) -> UserProfile:
    """
    FastAPI dependency that validates the JWT Bearer token and returns the current user.
    Raises HTTP 401 if token is missing or invalid.
    """
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required. Please provide a Bearer token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials

    try:
        payload = decode_token(token, expected_type="access")
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: missing user ID.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = get_user_by_id(user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account not found or has been deleted.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return user


async def get_verified_user(
    current_user: UserProfile = Depends(get_current_user),
) -> UserProfile:
    """
    Extension of get_current_user that additionally requires the email to be verified.
    Raises HTTP 403 if the user's email has not been verified.
    """
    if not current_user.is_email_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Email verification is required to access this resource.",
        )
    return current_user
