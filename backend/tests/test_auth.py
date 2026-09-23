"""
Unit tests for /auth endpoints.
These tests run against the in-memory mock store (no Firebase credentials required).
"""
import pytest
from fastapi.testclient import TestClient
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.main import app
from app.services import auth_service

client = TestClient(app)


def _fresh_email(base: str = "test") -> str:
    """Generate a unique email for each test to avoid cross-test contamination."""
    import time
    ts = int(time.time() * 1000)
    return f"{base}_{ts}@furrmind.com"


# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------

def test_register_success():
    email = _fresh_email("reg")
    response = client.post("/auth/register", json={
        "email": email,
        "password": "securepass123",
        "display_name": "Test User",
    })
    assert response.status_code == 201
    data = response.json()
    assert data["success"] is True
    assert "verification code" in data["message"].lower()


def test_register_duplicate_email():
    email = _fresh_email("dup")
    payload = {"email": email, "password": "securepass123"}
    client.post("/auth/register", json=payload)
    response = client.post("/auth/register", json=payload)
    assert response.status_code == 400
    assert "already registered" in response.json()["detail"].lower()


def test_register_short_password():
    response = client.post("/auth/register", json={
        "email": _fresh_email("short"),
        "password": "abc",
    })
    assert response.status_code == 422  # Pydantic validation error


def test_register_invalid_email():
    response = client.post("/auth/register", json={
        "email": "not-an-email",
        "password": "securepass123",
    })
    assert response.status_code == 422


# ---------------------------------------------------------------------------
# Email Verification
# ---------------------------------------------------------------------------

def test_verify_email_success():
    email = _fresh_email("verify")
    client.post("/auth/register", json={"email": email, "password": "securepass123"})
    otp = auth_service._mock_otps.get(f"{email}_verify_email", {}).get("code")
    assert otp is not None, "OTP not found in mock store after registration"
    response = client.post("/auth/verify-email", json={"email": email, "code": otp})
    assert response.status_code == 200
    assert response.json()["success"] is True


def test_verify_email_wrong_code():
    email = _fresh_email("wrongcode")
    client.post("/auth/register", json={"email": email, "password": "securepass123"})
    response = client.post("/auth/verify-email", json={"email": email, "code": "000000"})
    assert response.status_code == 400
    assert "invalid" in response.json()["detail"].lower()


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------

def _register_and_verify(email: str, password: str = "securepass123"):
    """Helper: register + verify email, returns the user record."""
    client.post("/auth/register", json={"email": email, "password": password})
    otp = auth_service._mock_otps.get(f"{email}_verify_email", {}).get("code")
    if otp:
        client.post("/auth/verify-email", json={"email": email, "code": otp})


def test_login_success():
    email = _fresh_email("login")
    _register_and_verify(email)
    response = client.post("/auth/login", json={"email": email, "password": "securepass123"})
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


def test_login_wrong_password():
    email = _fresh_email("wrongpw")
    _register_and_verify(email)
    response = client.post("/auth/login", json={"email": email, "password": "wrongpassword"})
    assert response.status_code == 401


def test_login_unregistered_email():
    response = client.post("/auth/login", json={"email": "ghost@furrmind.com", "password": "anypass"})
    assert response.status_code == 401


# ---------------------------------------------------------------------------
# Token Refresh
# ---------------------------------------------------------------------------

def test_refresh_token_success():
    email = _fresh_email("refresh")
    _register_and_verify(email)
    login_resp = client.post("/auth/login", json={"email": email, "password": "securepass123"})
    refresh_token = login_resp.json()["refresh_token"]

    response = client.post("/auth/refresh", json={"refresh_token": refresh_token})
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data


def test_refresh_token_invalid():
    response = client.post("/auth/refresh", json={"refresh_token": "not.a.valid.token"})
    assert response.status_code == 401


# ---------------------------------------------------------------------------
# Get Me (/auth/me)
# ---------------------------------------------------------------------------

def test_get_me_authenticated():
    email = _fresh_email("me")
    _register_and_verify(email)
    login_resp = client.post("/auth/login", json={"email": email, "password": "securepass123"})
    access_token = login_resp.json()["access_token"]

    response = client.get("/auth/me", headers={"Authorization": f"Bearer {access_token}"})
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == email


def test_get_me_unauthenticated():
    response = client.get("/auth/me")
    assert response.status_code == 401


def test_get_me_invalid_token():
    response = client.get("/auth/me", headers={"Authorization": "Bearer invalid.token.here"})
    assert response.status_code == 401


# ---------------------------------------------------------------------------
# Forgot & Reset Password
# ---------------------------------------------------------------------------

def test_forgot_password_always_succeeds():
    # Should succeed even for non-existent emails (anti-enumeration)
    response = client.post("/auth/forgot-password", json={"email": "ghost@furrmind.com"})
    assert response.status_code == 200
    assert response.json()["success"] is True


def test_reset_password_success():
    email = _fresh_email("reset")
    _register_and_verify(email)
    client.post("/auth/forgot-password", json={"email": email})

    otp = auth_service._mock_otps.get(f"{email}_reset_password", {}).get("code")
    assert otp is not None, "Reset OTP not in mock store"

    response = client.post("/auth/reset-password", json={
        "email": email,
        "code": otp,
        "new_password": "newpassword456",
    })
    assert response.status_code == 200

    # Verify new password works
    login_resp = client.post("/auth/login", json={"email": email, "password": "newpassword456"})
    assert login_resp.status_code == 200


def test_reset_password_wrong_code():
    email = _fresh_email("resetwrong")
    _register_and_verify(email)
    client.post("/auth/forgot-password", json={"email": email})
    response = client.post("/auth/reset-password", json={
        "email": email,
        "code": "000000",
        "new_password": "newpassword456",
    })
    assert response.status_code == 400


# ---------------------------------------------------------------------------
# Logout
# ---------------------------------------------------------------------------

def test_logout_authenticated():
    email = _fresh_email("logout")
    _register_and_verify(email)
    login_resp = client.post("/auth/login", json={"email": email, "password": "securepass123"})
    access_token = login_resp.json()["access_token"]

    response = client.post("/auth/logout", headers={"Authorization": f"Bearer {access_token}"})
    assert response.status_code == 200
    assert response.json()["success"] is True


def test_logout_unauthenticated():
    response = client.post("/auth/logout")
    assert response.status_code == 401
