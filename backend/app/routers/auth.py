import logging
from fastapi import APIRouter, HTTPException, status, Depends

from app.models.schemas import (
    RegisterRequest,
    LoginRequest,
    TokenResponse,
    TokenRefreshRequest,
    VerifyEmailRequest,
    ResendCodeRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    MessageResponse,
    UserProfile,
)
from app.services import auth_service
from app.middleware.auth_middleware import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def register(req: RegisterRequest):
    """Register a new user account. A 6-digit OTP will be emailed for verification."""
    try:
        profile, _ = auth_service.register_user(req)
        return MessageResponse(
            message=f"Account created. A verification code has been sent to {profile.email}.",
            success=True,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        logger.error(f"Register error: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Registration failed. Please try again.")


@router.post("/verify-email", response_model=MessageResponse)
async def verify_email(req: VerifyEmailRequest):
    """Verify the user's email address using the 6-digit OTP code."""
    ok = auth_service.verify_email(req.email, req.code)
    if not ok:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired verification code.",
        )
    return MessageResponse(message="Email verified successfully. You can now log in.", success=True)


@router.post("/resend-code", response_model=MessageResponse)
async def resend_code(req: ResendCodeRequest):
    """Resend the email verification OTP."""
    try:
        auth_service.resend_verification(req.email)
        return MessageResponse(message="Verification code resent. Please check your email.", success=True)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        logger.error(f"Resend code error: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to resend code.")


@router.post("/login", response_model=TokenResponse)
async def login(req: LoginRequest):
    """Authenticate user credentials and return JWT access & refresh tokens."""
    try:
        _, tokens = auth_service.authenticate_user(req.email, req.password)
        return tokens
    except PermissionError as e:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
    except Exception as e:
        logger.error(f"Login error: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Login failed. Please try again.")


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(req: TokenRefreshRequest):
    """Refresh the access token using a valid refresh token."""
    try:
        tokens = auth_service.refresh_user_tokens(req.refresh_token)
        return tokens
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
    except Exception as e:
        logger.error(f"Token refresh error: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Token refresh failed.")


@router.post("/logout", response_model=MessageResponse)
async def logout(current_user: UserProfile = Depends(get_current_user)):
    """Logout the current user. Client should discard tokens after this call."""
    # Stateless JWT — no server-side token revocation in this implementation.
    # Future: blacklist tokens in Redis or Firestore for extra security.
    return MessageResponse(message="Logged out successfully.", success=True)


@router.post("/forgot-password", response_model=MessageResponse)
async def forgot_password(req: ForgotPasswordRequest):
    """Initiate a password reset by sending a 6-digit OTP to the user's email."""
    # Always returns success to prevent user enumeration
    auth_service.request_password_reset(req.email)
    return MessageResponse(
        message="If this email is registered, a password reset code has been sent.",
        success=True,
    )


@router.post("/reset-password", response_model=MessageResponse)
async def reset_password(req: ResetPasswordRequest):
    """Reset the user's password using the OTP code received via email."""
    try:
        auth_service.reset_user_password(req.email, req.code, req.new_password)
        return MessageResponse(message="Password reset successfully. You can now log in.", success=True)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        logger.error(f"Reset password error: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Password reset failed.")


@router.get("/me", response_model=UserProfile)
async def get_me(current_user: UserProfile = Depends(get_current_user)):
    """Get the currently authenticated user's profile."""
    return current_user
