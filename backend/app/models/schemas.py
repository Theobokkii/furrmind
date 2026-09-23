from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, EmailStr, Field


class PredictRequest(BaseModel):
    text: str


class DistortionResult(BaseModel):
    label: str
    confidence: float
    triggered: bool


class PredictResponse(BaseModel):
    distortions: List[DistortionResult]


class ReframeRequest(BaseModel):
    text: str
    detected_distortions: List[str]


class ReframeResponse(BaseModel):
    reframe: str
    explanation: str
    sources: List[str]


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool


# --- Auth & User Schemas ---

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6, description="Password must be at least 6 characters")
    display_name: Optional[str] = Field(None, max_length=50)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class TokenRefreshRequest(BaseModel):
    refresh_token: str


class VerifyEmailRequest(BaseModel):
    email: EmailStr
    code: str = Field(..., min_length=6, max_length=6, description="6-digit verification code")


class ResendCodeRequest(BaseModel):
    email: EmailStr


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str = Field(..., min_length=6, max_length=6, description="6-digit verification code")
    new_password: str = Field(..., min_length=6, description="New password with min 6 characters")


class UserProfile(BaseModel):
    id: str
    email: EmailStr
    display_name: Optional[str] = None
    photo_url: Optional[str] = None
    is_email_verified: bool = False
    created_at: Optional[datetime] = None


class MessageResponse(BaseModel):
    message: str
    success: bool = True


# --- Journal & Mood Schemas ---

class JournalCreateRequest(BaseModel):
    content: str = Field(..., min_length=1, description="Journal entry text (also used for ML prediction)")
    title: Optional[str] = Field(None, max_length=200)
    mood_score: Optional[int] = Field(None, ge=1, le=10, description="Mood score 1-10")
    tags: Optional[List[str]] = Field(default_factory=list)


class JournalEntryResponse(BaseModel):
    id: str
    user_id: str
    title: str
    content: str
    mood_score: Optional[int] = None
    distortions: List[dict] = []
    reframe: str = ""
    tags: List[str] = []
    created_at: str
    updated_at: str


class MoodLogRequest(BaseModel):
    level: int = Field(..., ge=1, le=10, description="Mood level 1 (very low) to 10 (excellent)")
    note: Optional[str] = Field(None, max_length=500)


class MoodEntryResponse(BaseModel):
    id: str
    user_id: str
    level: int
    note: str
    created_at: str


class UserProfileUpdateRequest(BaseModel):
    display_name: Optional[str] = Field(None, max_length=50)
    photo_url: Optional[str] = None
