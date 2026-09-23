"""
MVP Data Layer — Journal + Mood + User DB Services
Uses Firestore when credentials are available, falls back to in-memory dict otherwise.
Same graceful-fallback pattern as auth_service.py.
"""
import uuid
import logging
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any

from app.services.firebase_service import get_db

logger = logging.getLogger(__name__)

# ─── In-memory fallback stores ────────────────────────────────────────────────
_mock_journals: Dict[str, Dict[str, Any]] = {}   # key: journal_id
_mock_moods:    Dict[str, Dict[str, Any]] = {}   # key: mood_id
_mock_profiles: Dict[str, Dict[str, Any]] = {}   # key: user_id


# ══════════════════════════════════════════════════════════════════════════════
# Helpers
# ══════════════════════════════════════════════════════════════════════════════

def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _doc_to_dict(doc) -> Dict[str, Any]:
    """Convert Firestore DocumentSnapshot to plain dict with 'id' field."""
    d = doc.to_dict()
    d["id"] = doc.id
    return d


# ══════════════════════════════════════════════════════════════════════════════
# USER PROFILE
# ══════════════════════════════════════════════════════════════════════════════

def create_user_profile(user_id: str, email: str, display_name: Optional[str] = None) -> Dict[str, Any]:
    """Create a user profile document (called after successful registration)."""
    profile = {
        "id": user_id,
        "email": email,
        "display_name": display_name or "",
        "photo_url": None,
        "streak_days": 0,
        "total_entries": 0,
        "created_at": _now_iso(),
        "updated_at": _now_iso(),
    }

    db = get_db()
    if db:
        try:
            db.collection("users").document(user_id).set(profile, merge=True)
        except Exception as e:
            logger.warning(f"Firestore create_user_profile error: {e}")

    _mock_profiles[user_id] = profile
    return profile


def get_user_profile(user_id: str) -> Optional[Dict[str, Any]]:
    db = get_db()
    if db:
        try:
            doc = db.collection("users").document(user_id).get()
            if doc.exists:
                return _doc_to_dict(doc)
        except Exception as e:
            logger.warning(f"Firestore get_user_profile error: {e}")

    return _mock_profiles.get(user_id)


def update_user_profile(user_id: str, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    allowed = {"display_name", "photo_url"}
    clean = {k: v for k, v in data.items() if k in allowed}
    clean["updated_at"] = _now_iso()

    db = get_db()
    if db:
        try:
            db.collection("users").document(user_id).update(clean)
        except Exception as e:
            logger.warning(f"Firestore update_user_profile error: {e}")

    if user_id in _mock_profiles:
        _mock_profiles[user_id].update(clean)

    return get_user_profile(user_id)


# ══════════════════════════════════════════════════════════════════════════════
# JOURNAL
# ══════════════════════════════════════════════════════════════════════════════

def create_journal_entry(
    user_id: str,
    content: str,
    title: Optional[str] = None,
    mood_score: Optional[int] = None,
    distortions: Optional[List[Dict[str, Any]]] = None,
    reframe: Optional[str] = None,
    tags: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """Persist a journal entry (with optional ML results attached)."""
    journal_id = str(uuid.uuid4())
    now = _now_iso()

    entry = {
        "id": journal_id,
        "user_id": user_id,
        "title": title or "",
        "content": content,
        "mood_score": mood_score,            # 1-10 scale
        "distortions": distortions or [],     # raw ML results from onnx_service
        "reframe": reframe or "",
        "tags": tags or [],
        "created_at": now,
        "updated_at": now,
    }

    db = get_db()
    if db:
        try:
            db.collection("users").document(user_id)\
              .collection("journals").document(journal_id).set(entry)
            # Increment counter on profile
            try:
                from google.cloud.firestore import Increment
                db.collection("users").document(user_id).update(
                    {"total_entries": Increment(1), "updated_at": now}
                )
            except Exception:
                pass
        except Exception as e:
            logger.warning(f"Firestore create_journal_entry error: {e}")

    _mock_journals[journal_id] = entry
    if user_id in _mock_profiles:
        _mock_profiles[user_id]["total_entries"] = _mock_profiles[user_id].get("total_entries", 0) + 1

    return entry


def get_journal_entries(
    user_id: str,
    limit: int = 20,
    offset: int = 0,
) -> List[Dict[str, Any]]:
    """Get a paginated list of journal entries for a user, newest first."""
    db = get_db()
    if db:
        try:
            query = (
                db.collection("users").document(user_id)
                  .collection("journals")
                  .order_by("created_at", direction="DESCENDING")
                  .limit(limit)
            )
            docs = query.stream()
            return [_doc_to_dict(d) for d in docs]
        except Exception as e:
            logger.warning(f"Firestore get_journal_entries error: {e}")

    # In-memory: filter by user_id, sort newest first
    entries = [e for e in _mock_journals.values() if e["user_id"] == user_id]
    entries.sort(key=lambda x: x["created_at"], reverse=True)
    return entries[offset:offset + limit]


def get_journal_entry(user_id: str, journal_id: str) -> Optional[Dict[str, Any]]:
    db = get_db()
    if db:
        try:
            doc = db.collection("users").document(user_id)\
                    .collection("journals").document(journal_id).get()
            if doc.exists:
                return _doc_to_dict(doc)
        except Exception as e:
            logger.warning(f"Firestore get_journal_entry error: {e}")

    entry = _mock_journals.get(journal_id)
    if entry and entry["user_id"] == user_id:
        return entry
    return None


def delete_journal_entry(user_id: str, journal_id: str) -> bool:
    db = get_db()
    if db:
        try:
            db.collection("users").document(user_id)\
              .collection("journals").document(journal_id).delete()
        except Exception as e:
            logger.warning(f"Firestore delete_journal_entry error: {e}")

    entry = _mock_journals.pop(journal_id, None)
    return entry is not None


# ══════════════════════════════════════════════════════════════════════════════
# MOOD
# ══════════════════════════════════════════════════════════════════════════════

def log_mood(user_id: str, level: int, note: Optional[str] = None) -> Dict[str, Any]:
    """Log a mood entry (level 1-10)."""
    level = max(1, min(10, level))
    mood_id = str(uuid.uuid4())
    now = _now_iso()

    entry = {
        "id": mood_id,
        "user_id": user_id,
        "level": level,
        "note": note or "",
        "created_at": now,
    }

    db = get_db()
    if db:
        try:
            db.collection("users").document(user_id)\
              .collection("moods").document(mood_id).set(entry)
        except Exception as e:
            logger.warning(f"Firestore log_mood error: {e}")

    _mock_moods[mood_id] = entry
    return entry


def get_recent_moods(user_id: str, limit: int = 7) -> List[Dict[str, Any]]:
    """Get the most recent mood entries for a user."""
    db = get_db()
    if db:
        try:
            query = (
                db.collection("users").document(user_id)
                  .collection("moods")
                  .order_by("created_at", direction="DESCENDING")
                  .limit(limit)
            )
            return [_doc_to_dict(d) for d in query.stream()]
        except Exception as e:
            logger.warning(f"Firestore get_recent_moods error: {e}")

    moods = [m for m in _mock_moods.values() if m["user_id"] == user_id]
    moods.sort(key=lambda x: x["created_at"], reverse=True)
    return moods[:limit]
