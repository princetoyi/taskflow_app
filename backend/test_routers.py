# backend/test_routers.py
# Integration tests for routers registered in backend/main.py.

import pytest
from fastapi.testclient import TestClient
from main import app
from core.security import verify_token

# Mock verify_token dependency for testing protected routes
def mock_verify_token():
    return {"uid": "stub-uid-001", "email": "test@example.com", "name": "Test User"}

app.dependency_overrides[verify_token] = mock_verify_token
client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_auth_login():
    response = client.post("/auth/login", json={
        "email": "test@example.com",
        "password": "password123"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["uid"] == "stub-uid-001"
    assert data["email"] == "test@example.com"
    assert "token" in data


def test_auth_signup():
    response = client.post("/auth/signup", json={
        "email": "newuser@example.com",
        "password": "password123"
    })
    # Since we are using mock fallback when firebase-admin credentials aren't set
    assert response.status_code in [200, 201]
    data = response.json()
    assert "token" in data
    assert "email" in data


def test_tasks_crud():
    # 1. Get initial tasks
    response = client.get("/tasks/")
    assert response.status_code == 200
    tasks = response.json()
    assert len(tasks) >= 2
    assert tasks[0]["completed"] is True
    assert tasks[0]["owner_uid"] == "stub-uid-001"
    assert tasks[0]["priority"] == "high"

    # 2. Create task
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

    # 3. Update task (PUT)
    task_id = new_task["id"]
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
    assert response.json()["theme"] == "light"

    # 2. Update preference (PUT)
    response = client.put("/users/preferences", json={"theme": "dark"})
    assert response.status_code == 200
    assert response.json()["theme"] == "dark"

    # 3. Verify updated preference
    response = client.get("/users/preferences")
    assert response.status_code == 200
    assert response.json()["theme"] == "dark"


def test_notifications():
    # 1. Post FCM token
    response = client.post("/notifications/fcm-token", json={"fcm_token": "fcm-token-12345"})
    assert response.status_code == 200
    assert "updated" in response.json()["message"]

    # 2. Get notifications
    response = client.get("/notifications/")
    assert response.status_code == 200
    notifs = response.json()
    assert len(notifs) >= 2
    assert notifs[0]["is_read"] is False

    # 3. Mark notification as read
    notif_id = notifs[0]["id"]
    response = client.put(f"/notifications/{notif_id}/read")
    assert response.status_code == 200
    assert response.json()["is_read"] is True
