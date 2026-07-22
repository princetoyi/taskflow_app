# backend/test_routers.py
# Integration tests for routers registered in backend/main.py.

import pytest
from fastapi.testclient import TestClient
from main import app
from core.security import verify_token

# Mock verify_token dependency for testing protected routes
def mock_verify_token():
    return {"uid": "test-uid-pytest", "email": "test@example.com", "name": "Test User"}

app.dependency_overrides[verify_token] = mock_verify_token
client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_auth_login():
    # Login with real Firebase test user (create this user in Firebase Console)
    response = client.post("/auth/login", json={
        "email": "test@example.com",
        "password": "password123"
    })
    # 200 = success, 401 = test user not created yet in Firebase Console (acceptable)
    assert response.status_code in [200, 401]
    if response.status_code == 200:
        data = response.json()
        assert "token" in data
        assert "email" in data
        assert "role" in data


def test_auth_signup():
    import uuid
    unique_email = f"testuser_{uuid.uuid4().hex[:8]}@example.com"
    response = client.post("/auth/signup", json={
        "email": unique_email,
        "password": "password123",
        "role": "worker"
    })
    assert response.status_code in [200, 201]
    data = response.json()
    assert "token" in data
    assert "email" in data
    assert "role" in data


def test_tasks_crud():
    # 1. Create a task first (so we don't depend on pre-existing data)
    response = client.post("/tasks/", json={
        "title": "New integration task",
        "description": "Integration test description",
        "priority": "high",
        "deadline": "2026-06-12T12:00:00Z"
    })
    assert response.status_code == 201
    new_task = response.json()
    assert new_task["title"] == "New integration task"
    assert new_task["completed"] is False
    assert new_task["priority"] == "high"
    assert new_task["deadline"] == "2026-06-12T12:00:00Z"
    assert new_task["owner_uid"] == "test-uid-pytest"

    task_id = new_task["id"]

    # 2. Get all tasks - should include the one we just created
    response = client.get("/tasks/")
    assert response.status_code == 200
    tasks = response.json()
    assert any(t["id"] == task_id for t in tasks)

    # 3. Update task (PUT)
    response = client.put(f"/tasks/{task_id}", json={
        "completed": True,
        "priority": "medium"
    })
    assert response.status_code == 200
    updated_task = response.json()
    assert updated_task["completed"] is True
    assert updated_task["priority"] == "medium"

    # 4. Get specific task
    response = client.get(f"/tasks/{task_id}")
    assert response.status_code == 200
    assert response.json()["completed"] is True

    # 5. Delete task
    response = client.delete(f"/tasks/{task_id}")
    assert response.status_code == 204

    # 6. Verify deleted task is gone
    response = client.get(f"/tasks/{task_id}")
    assert response.status_code == 404


def test_users_preferences():
    # 1. Get default preference
    response = client.get("/users/preferences")
    assert response.status_code == 200
    data = response.json()
    assert "theme" in data
    assert "role" in data

    # 2. Update preference to dark + manager
    response = client.put("/users/preferences", json={"theme": "dark", "role": "manager"})
    assert response.status_code == 200
    assert response.json()["theme"] == "dark"
    assert response.json()["role"] == "manager"

    # 3. Verify updated preference persisted
    response = client.get("/users/preferences")
    assert response.status_code == 200
    assert response.json()["theme"] == "dark"

    # 4. Reset back to light/worker
    client.put("/users/preferences", json={"theme": "light", "role": "worker"})


def test_notifications():
    # 1. Post FCM token
    response = client.post("/notifications/fcm-token", json={"fcm_token": "fcm-token-12345"})
    assert response.status_code == 200
    assert "updated" in response.json()["message"]

    # 2. Get notifications
    response = client.get("/notifications/")
    assert response.status_code == 200
    notifs = response.json()
    assert isinstance(notifs, list)

    # 3. Mark notification as read if any exist
    if len(notifs) > 0:
        notif_id = notifs[0]["id"]
        response = client.put(f"/notifications/{notif_id}/read")
        assert response.status_code == 200
        assert response.json()["is_read"] is True