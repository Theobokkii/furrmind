"""
Journal Router — MVP
POST /journal        → predict distortions (ONNX) + save entry
GET  /journal        → list entries (newest first)
GET  /journal/{id}   → single entry
DELETE /journal/{id} → delete entry

POST /mood           → log mood
GET  /mood           → last 7 moods

GET  /profile        → current user profile
PATCH /profile       → update display_name / photo_url
"""
import logging
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Depends, status, Query

from app.models.schemas import (
    JournalCreateRequest,
    JournalEntryResponse,
    MoodLogRequest,
    MoodEntryResponse,
    UserProfileUpdateRequest,
    UserProfile,
    MessageResponse,
)
from app.middleware.auth_middleware import get_current_user
from app.services import db_service
from app.services import onnx_service
from app.services import guardrail_service

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Journal & Mood"])


# ─────────────────────────────────────────────────────────────────────────────
# JOURNAL
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/journal", response_model=JournalEntryResponse, status_code=status.HTTP_201_CREATED)
async def create_journal_entry(
    req: JournalCreateRequest,
    current_user: UserProfile = Depends(get_current_user),
):
    """
    Submit a journal entry.
    Runs guardrail check, then runs ONNX distortion-detection model,
    and persists the entry + ML results together.
    """
    # 1. Crisis guardrail check
    try:
        guardrail_result = guardrail_service.check_guardrail(req.content)
        if guardrail_result.get("type") == "crisis":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "code": "CRISIS_DETECTED",
                    "message": guardrail_result.get("message", "Crisis content detected. Please reach out to a mental health professional."),
                    "resources": guardrail_result.get("resources", []),
                },
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.warning(f"Guardrail check failed (non-fatal): {e}")

    # 2. Run ONNX distortion detection (deep-learning model)
    distortions: List[dict] = []
    try:
        distortions = onnx_service.predict(req.content)
    except Exception as e:
        logger.warning(f"ONNX prediction skipped (model not loaded?): {e}")
        # MVP: proceed without ML if model not loaded yet

    # 3. Persist entry with ML results attached
    try:
        entry = db_service.create_journal_entry(
            user_id=current_user.id,
            content=req.content,
            title=req.title or "",
            mood_score=req.mood_score,
            distortions=distortions,
            tags=req.tags or [],
        )
        return entry
    except Exception as e:
        logger.error(f"create_journal_entry DB error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to save journal entry.",
        )


@router.get("/journal", response_model=List[JournalEntryResponse])
async def list_journal_entries(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    current_user: UserProfile = Depends(get_current_user),
):
    """Get paginated journal history for the current user, newest first."""
    try:
        return db_service.get_journal_entries(current_user.id, limit=limit, offset=offset)
    except Exception as e:
        logger.error(f"list_journal_entries error: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to fetch entries.")


@router.get("/journal/{journal_id}", response_model=JournalEntryResponse)
async def get_journal_entry(
    journal_id: str,
    current_user: UserProfile = Depends(get_current_user),
):
    """Get a single journal entry by ID."""
    entry = db_service.get_journal_entry(current_user.id, journal_id)
    if not entry:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Journal entry not found.")
    return entry


@router.delete("/journal/{journal_id}", response_model=MessageResponse)
async def delete_journal_entry(
    journal_id: str,
    current_user: UserProfile = Depends(get_current_user),
):
    """Delete a journal entry."""
    deleted = db_service.delete_journal_entry(current_user.id, journal_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Journal entry not found.")
    return MessageResponse(message="Journal entry deleted.", success=True)


# ─────────────────────────────────────────────────────────────────────────────
# MOOD
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/mood", response_model=MoodEntryResponse, status_code=status.HTTP_201_CREATED)
async def log_mood(
    req: MoodLogRequest,
    current_user: UserProfile = Depends(get_current_user),
):
    """Log a mood score (1-10) with an optional note."""
    try:
        entry = db_service.log_mood(current_user.id, req.level, req.note)
        return entry
    except Exception as e:
        logger.error(f"log_mood error: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to log mood.")


@router.get("/mood", response_model=List[MoodEntryResponse])
async def get_recent_moods(
    limit: int = Query(default=7, ge=1, le=30),
    current_user: UserProfile = Depends(get_current_user),
):
    """Get recent mood entries (default: last 7 days)."""
    try:
        return db_service.get_recent_moods(current_user.id, limit=limit)
    except Exception as e:
        logger.error(f"get_recent_moods error: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to fetch moods.")


# ─────────────────────────────────────────────────────────────────────────────
# PROFILE
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/profile", response_model=dict)
async def get_profile(current_user: UserProfile = Depends(get_current_user)):
    """Get the current user's extended profile (streak, entry count, etc.)."""
    profile = db_service.get_user_profile(current_user.id)
    if not profile:
        # Auto-create profile if missing (handles users registered before profile creation)
        profile = db_service.create_user_profile(
            user_id=current_user.id,
            email=current_user.email,
            display_name=current_user.display_name,
        )
    return profile


@router.patch("/profile", response_model=dict)
async def update_profile(
    req: UserProfileUpdateRequest,
    current_user: UserProfile = Depends(get_current_user),
):
    """Update display name or photo URL."""
    data = req.model_dump(exclude_none=True)
    if not data:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update.")
    updated = db_service.update_user_profile(current_user.id, data)
    if not updated:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found.")
    return updated
