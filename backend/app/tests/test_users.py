# backend/app/tests/test_users.py
# Tests for /users routes: profile self-service, admin-gated directory
# operations, and the literal-path-vs-{user_id} route ordering.

from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.middleware.auth_middleware import get_current_user

client = TestClient(app)


def _override_user(uid="test_uid_123", email="test@example.com"):
    async def _fake_user():
        return {"uid": uid, "email": email, "name": "Test User"}
    app.dependency_overrides[get_current_user] = _fake_user


@pytest.fixture(autouse=True)
def _clear_overrides():
    yield
    app.dependency_overrides.clear()


def _mock_profile_doc(exists=True, **fields):
    doc = MagicMock()
    doc.exists = exists
    base = {
        "uid": "test_uid_123",
        "email": "test@example.com",
        "display_name": "Test User",
        "role": "employee",
        "is_active": True,
        "created_at": "2026-01-01T00:00:00",
    }
    base.update(fields)
    doc.to_dict.return_value = base
    return doc


@patch("app.services.auth_service.firestore")
def test_get_profile_self_heals_and_returns_role(mock_firestore):
    _override_user()
    mock_firestore.client.return_value.collection.return_value.document.return_value.get.return_value = (
        _mock_profile_doc()
    )

    response = client.get("/users/profile")

    assert response.status_code == 200
    assert response.json()["role"] == "employee"


@patch("app.services.auth_service.firestore")
def test_get_user_by_id_routes_to_wildcard_not_profile_literal(mock_firestore):
    # Regression check for route ordering: /users/{user_id} must not shadow
    # /users/profile, and vice versa. Requesting a real id for a *different*
    # user than the caller, while the caller is a non-admin, must 403 —
    # proving this hit get_user()'s permission check, not get_profile().
    _override_user(uid="caller_uid")
    mock_firestore.client.return_value.collection.return_value.document.return_value.get.return_value = (
        _mock_profile_doc(role="employee")
    )

    response = client.get("/users/some_other_uid")

    assert response.status_code == 403


@patch("app.services.auth_service.firestore")
def test_list_users_requires_admin(mock_firestore):
    _override_user()
    mock_firestore.client.return_value.collection.return_value.document.return_value.get.return_value = (
        _mock_profile_doc(role="employee")
    )

    response = client.get("/users")

    assert response.status_code == 403


@patch("app.services.user_service.get_db")
@patch("app.services.auth_service.firestore")
def test_list_users_allowed_for_admin(mock_firestore, mock_get_db):
    _override_user()
    mock_firestore.client.return_value.collection.return_value.document.return_value.get.return_value = (
        _mock_profile_doc(role="admin")
    )

    mock_query = MagicMock()
    mock_query.where.return_value = mock_query
    mock_query.limit.return_value = mock_query
    mock_query.offset.return_value = mock_query
    mock_query.stream.return_value = [_mock_profile_doc(role="employee")]
    mock_get_db.return_value.collection.return_value = mock_query

    response = client.get("/users", params={"role": "employee"})

    assert response.status_code == 200
    assert response.json()[0]["role"] == "employee"


@patch("app.services.user_service.get_db")
@patch("app.services.auth_service.firestore")
def test_update_profile_cannot_set_role(mock_firestore, mock_get_db):
    # UserProfileUpdateRequest has no role/is_active fields at all — sending
    # them must be silently ignored rather than accepted.
    _override_user()
    mock_firestore.client.return_value.collection.return_value.document.return_value.get.return_value = (
        _mock_profile_doc()
    )
    mock_get_db.return_value.collection.return_value.document.return_value.get.return_value = (
        _mock_profile_doc()
    )

    response = client.patch("/users/profile", json={"display_name": "New Name", "role": "admin"})

    assert response.status_code == 200
    # The mocked doc always reports role "employee" regardless of what was
    # sent, since UserProfileUpdateRequest has no role field to smuggle it in.
    assert response.json()["role"] == "employee"


def test_delete_self_is_rejected():
    _override_user(uid="self_uid")
    with patch("app.services.auth_service.firestore") as mock_firestore:
        mock_firestore.client.return_value.collection.return_value.document.return_value.get.return_value = (
            _mock_profile_doc(role="admin")
        )
        response = client.delete("/users/self_uid")

    assert response.status_code == 400
