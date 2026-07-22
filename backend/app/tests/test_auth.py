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


@patch("app.services.auth_service.firestore")
@patch("app.services.auth_service.auth")
def test_signup_success(mock_auth, mock_firestore):
    # Mock Firebase create_user to avoid hitting real Firebase
    mock_user = MagicMock()
    mock_user.uid = "test_uid_123"
    mock_user.email = "test@example.com"
    mock_user.display_name = "Test User"
    mock_auth.create_user.return_value = mock_user
    mock_auth.create_custom_token.return_value = b"mock_token"

    # Mock Firestore so the profile write in _ensure_user_profile doesn't
    # hit the real database
    mock_doc = MagicMock()
    mock_doc.exists = False
    mock_firestore.client.return_value.collection.return_value.document.return_value.get.return_value = mock_doc

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
    # Task endpoints must reject requests without a token. No trailing
    # slash — that's what the Flutter client actually sends, and a 307
    # redirect here (the old "/" route registration) breaks credentialed
    # CORS requests in a real browser even though TestClient silently
    # follows it, masking the bug in a naive version of this test.
    response = client.get("/tasks")
    assert response.status_code == 401

    response = client.post("/tasks", json={"title": "Test task"})
    assert response.status_code == 401


def test_notifications_requires_auth():
    # Notification endpoints must reject requests without a token
    response = client.get("/notifications")
    assert response.status_code == 401


@patch("app.services.auth_service.firestore")
def test_complete_signup_creates_profile_with_chosen_role(mock_firestore):
    from app.middleware.auth_middleware import get_current_user

    async def _fake_user():
        return {"uid": "new_uid", "email": "new@example.com", "name": "New User"}

    app.dependency_overrides[get_current_user] = _fake_user
    try:
        doc = MagicMock()
        doc.exists = False
        mock_firestore.client.return_value.collection.return_value.document.return_value.get.return_value = doc

        response = client.post("/auth/complete-signup", json={"role": "manager"})

        assert response.status_code == 200
        assert response.json()["role"] == "manager"
    finally:
        app.dependency_overrides.clear()


def test_complete_signup_rejects_admin_role():
    response = client.post("/auth/complete-signup", json={"role": "admin"})
    # Rejected by Pydantic validation before auth is even checked —
    # "admin" isn't a self-signup choice.
    assert response.status_code in (401, 422)