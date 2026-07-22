# app/services/task_service.py
# All Firestore task operations — create, read, update, delete.
# Every query is scoped to the authenticated user's UID.

from datetime import datetime
from google.cloud.firestore_v1 import FieldFilter
from firebase_admin import firestore
from fastapi import HTTPException
from app.models.task import TaskCreate, TaskUpdate, TaskResponse

# Firestore collection name
TASKS_COLLECTION = "tasks"


def get_db():
    return firestore.client()


async def create_task(uid: str, data: TaskCreate) -> TaskResponse:
    db = get_db()
    task_ref = db.collection(TASKS_COLLECTION).document()

    task = {
        "id": task_ref.id,
        "owner_uid": uid,
        "title": data.title,
        "description": data.description,
        "completed": False,
        "priority": data.priority,
        "deadline": data.deadline.isoformat() if data.deadline else None,
        "created_at": datetime.utcnow().isoformat(),
    }

    task_ref.set(task)
    return TaskResponse(**task)


async def get_tasks(
    uid: str,
    status: str | None = None,
    priority: str | None = None,
    sort_by: str = "created_at",
    order: str = "asc",
    page: int = 1,
    page_size: int = 10,
) -> list[TaskResponse]:
    db = get_db()
    query = db.collection(TASKS_COLLECTION).where(
        filter=FieldFilter("owner_uid", "==", uid)
    )

    # Apply optional filters
    if status == "completed":
        query = query.where(filter=FieldFilter("completed", "==", True))
    elif status == "pending":
        query = query.where(filter=FieldFilter("completed", "==", False))

    if priority:
        query = query.where(filter=FieldFilter("priority", "==", priority))

    # Apply sorting
    from google.cloud.firestore_v1 import Query
    direction = Query.ASCENDING if order == "asc" else Query.DESCENDING
    query = query.order_by(sort_by, direction=direction)

    # Apply pagination
    offset = (page - 1) * page_size
    query = query.limit(page_size).offset(offset)

    try:
        docs = query.stream()
        return [TaskResponse(**doc.to_dict()) for doc in docs]
    except Exception as e:
        # Any Firestore-level failure here (e.g. a missing composite index)
        # must surface as an HTTPException, not an unhandled exception —
        # unhandled exceptions escape FastAPI's normal error-handling
        # middleware and land outside CORSMiddleware, which means the
        # browser sees a bare CORS failure instead of the real error.
        raise HTTPException(status_code=500, detail=f"Failed to fetch tasks: {e}")


async def get_task(uid: str, task_id: str) -> TaskResponse:
    db = get_db()
    doc = db.collection(TASKS_COLLECTION).document(task_id).get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail="Task not found")

    task = doc.to_dict()

    # Ensure the task belongs to the requesting user
    if task["owner_uid"] != uid:
        raise HTTPException(status_code=403, detail="Access denied")

    return TaskResponse(**task)


async def update_task(uid: str, task_id: str, data: TaskUpdate) -> TaskResponse:
    db = get_db()
    task_ref = db.collection(TASKS_COLLECTION).document(task_id)
    doc = task_ref.get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail="Task not found")

    if doc.to_dict()["owner_uid"] != uid:
        raise HTTPException(status_code=403, detail="Access denied")

    # Only update fields that were actually sent
    updates = data.model_dump(exclude_none=True)
    if "deadline" in updates and updates["deadline"]:
        updates["deadline"] = updates["deadline"].isoformat()

    task_ref.update(updates)

    updated = task_ref.get().to_dict()
    return TaskResponse(**updated)


async def delete_task(uid: str, task_id: str) -> dict:
    db = get_db()
    task_ref = db.collection(TASKS_COLLECTION).document(task_id)
    doc = task_ref.get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail="Task not found")

    if doc.to_dict()["owner_uid"] != uid:
        raise HTTPException(status_code=403, detail="Access denied")

    task_ref.delete()
    return {"message": "Task deleted successfully"}