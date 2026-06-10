# backend/app/tests/test_auth.py
# Integration tests for auth endpoints using FastAPI TestClient.
# These tests mock Firebase to avoid hitting the real service during CI.

import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health_check():
    # Confirm the server is alive
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert "running" in response.json()["message"]


@patch("app.services.auth_service.auth")
def test_signup_success(mock_auth):
    # Mock Firebase create_user to avoid hitting real Firebase
    mock_user = MagicMock()
    mock_user.uid = "test_uid_123"
    mock_user.email = "test@example.com"
    mock_user.display_name = "Test User"
    mock_auth.create_user.return_value = mock_user
    mock_auth.create_custom_token.return_value = b"mock_token"

    response = client.post("/auth/signup", json={
        "email": "test@example.com",
        "password": "TestPass123",
        "display_name": "Test User"
    })

    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "test@example.com"
    assert data["uid"] == "test_uid_123"
    assert "token" in data


@patch("app.services.auth_service.auth")
def test_signup_duplicate_email(mock_auth):
    # Should return 400 when email already exists
    mock_auth.create_user.side_effect = Exception("EMAIL_EXISTS")

    response = client.post("/auth/signup", json={
        "email": "existing@example.com",
        "password": "TestPass123",
        "display_name": "Test User"
    })

    assert response.status_code == 400  # caught by generic exception handler

def test_signup_invalid_email():
    # Pydantic should reject invalid email format
    response = client.post("/auth/signup", json={
        "email": "not-an-email",
        "password": "TestPass123",
        "display_name": "Test User"
    })
    assert response.status_code == 422


def test_tasks_requires_auth():
    # Task endpoints must reject requests without a token
    response = client.get("/tasks/")
    assert response.status_code == 401

    response = client.post("/tasks/", json={"title": "Test task"})
    assert response.status_code == 401


def test_notifications_requires_auth():
    # Notification endpoints must reject requests without a token
    response = client.get("/notifications/")
    assert response.status_code == 401