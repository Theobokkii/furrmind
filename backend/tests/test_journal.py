"""
Unit tests for the MVP Journal, Mood, and Profile endpoints.
"""
import pytest
from fastapi.testclient import TestClient
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.main import app
from app.services import db_service

client = TestClient(app)

# Helper to get an auth token for testing
def _get_auth_token(email: str = "journal_test@furrmind.com") -> str:
    # Register
    client.post("/auth/register", json={"email": email, "password": "securepass123", "display_name": "Test User"})
    # Verify
    otp = None
    from app.services import auth_service
    otp = auth_service._mock_otps.get(f"{email}_verify_email", {}).get("code")
    if otp:
        client.post("/auth/verify-email", json={"email": email, "code": otp})
    # Login
    resp = client.post("/auth/login", json={"email": email, "password": "securepass123"})
    return resp.json().get("access_token")


@pytest.fixture
def auth_headers():
    token = _get_auth_token()
    return {"Authorization": f"Bearer {token}"}


# ---------------------------------------------------------------------------
# Profile
# ---------------------------------------------------------------------------

def test_get_profile(auth_headers):
    response = client.get("/profile", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "email" in data
    assert "display_name" in data
    assert data["streak_days"] == 0
    assert data["total_entries"] == 0

def test_update_profile(auth_headers):
    response = client.patch(
        "/profile",
        headers=auth_headers,
        json={"display_name": "Updated Name", "photo_url": "http://example.com/photo.jpg"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["display_name"] == "Updated Name"
    assert data["photo_url"] == "http://example.com/photo.jpg"

def test_update_profile_empty(auth_headers):
    response = client.patch("/profile", headers=auth_headers, json={})
    assert response.status_code == 400


# ---------------------------------------------------------------------------
# Mood
# ---------------------------------------------------------------------------

def test_log_mood(auth_headers):
    response = client.post(
        "/mood",
        headers=auth_headers,
        json={"level": 8, "note": "Feeling good"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["level"] == 8
    assert data["note"] == "Feeling good"
    assert "id" in data

def test_log_mood_invalid_level(auth_headers):
    # Level must be 1-10
    response = client.post("/mood", headers=auth_headers, json={"level": 15, "note": ""})
    assert response.status_code == 422
    
    response = client.post("/mood", headers=auth_headers, json={"level": 0, "note": ""})
    assert response.status_code == 422

def test_get_recent_moods(auth_headers):
    # Log a couple moods
    client.post("/mood", headers=auth_headers, json={"level": 7})
    client.post("/mood", headers=auth_headers, json={"level": 8})
    
    response = client.get("/mood", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 2


# ---------------------------------------------------------------------------
# Journal
# ---------------------------------------------------------------------------

def test_create_journal(auth_headers):
    response = client.post(
        "/journal",
        headers=auth_headers,
        json={
            "title": "Good day",
            "content": "I had a great day today, everything went well.",
            "mood_score": 8,
            "tags": ["happy", "work"]
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Good day"
    assert "id" in data
    # Profile entry count should increment
    prof = client.get("/profile", headers=auth_headers).json()
    assert prof["total_entries"] > 0

def test_create_journal_crisis(auth_headers):
    response = client.post(
        "/journal",
        headers=auth_headers,
        json={"content": "I just want to end it all and kill myself."}
    )
    assert response.status_code == 400
    assert "CRISIS_DETECTED" in response.json()["detail"]["code"]

def test_get_journal_entries(auth_headers):
    response = client.get("/journal", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)

def test_get_single_journal(auth_headers):
    create_resp = client.post("/journal", headers=auth_headers, json={"content": "Test get single"})
    j_id = create_resp.json()["id"]
    
    get_resp = client.get(f"/journal/{j_id}", headers=auth_headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["id"] == j_id

def test_delete_journal(auth_headers):
    create_resp = client.post("/journal", headers=auth_headers, json={"content": "Test delete"})
    j_id = create_resp.json()["id"]
    
    del_resp = client.delete(f"/journal/{j_id}", headers=auth_headers)
    assert del_resp.status_code == 200
    
    get_resp = client.get(f"/journal/{j_id}", headers=auth_headers)
    assert get_resp.status_code == 404
