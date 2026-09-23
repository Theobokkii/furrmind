import pytest
from fastapi.testclient import TestClient
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert data["status"] == "ok"
    assert "model_loaded" in data


def test_predict_empty_text():
    response = client.post("/predict", json={"text": ""})
    assert response.status_code == 422


def test_predict_crisis_keyword():
    response = client.post("/predict", json={"text": "I want to kill myself"})
    assert response.status_code in [200, 400, 422]


def test_reframe_empty_text():
    response = client.post("/reframe", json={"text": "", "detected_distortions": ["Overgeneralization"]})
    assert response.status_code == 422


def test_reframe_empty_distortions():
    response = client.post("/reframe", json={"text": "I always fail", "detected_distortions": []})
    assert response.status_code == 422
