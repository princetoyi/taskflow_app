"""
routers/tasks.py
----------------
Router for /tasks endpoints using real Firestore reads/writes.
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel
from datetime import datetime, timezone
from typing import Literal
from core.security import verify_token
from core.firebase import db

router = APIRouter(prefix="/tasks", tags=["tasks"])


# ── Request / Response schemas ────────────────────────────────────────────────

class TaskCreateRequest(BaseModel):
    title: str
    description: str = ""
    priority: Literal["low", "medium", "high"] = "medium"
    deadline: str | None = None


class TaskUpdateRequest(BaseModel):
    title: str | None = None
    description: str | None = None
    completed: bool | None = None
    priority: Literal["low", "medium", "high"] | None = None
    deadline: str | None = None


class TaskResponse(BaseModel):
    id: str
    title: str
    description: str
    completed: bool
    created_at: str
    owner_uid: str
    priority: Literal["low", "medium", "high"]
    deadline: str | None = None


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/", response_model=list[TaskResponse], summary="Get all tasks for authenticated user")
async def get_tasks(
    status: str | None = Query(None, description="Filter: pending or completed"),
    priority: str | None = Query(None, description="Filter: low, medium, high"),
    sort_by: str = Query("created_at", description="Field to sort by"),
    order: str = Query("asc", description="asc or desc"),
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    decoded_token: dict = Depends(verify_token)
):
    uid = decoded_token.get("uid")

    if db is None:
        raise HTTPException(status_code=503, detail="Firestore not initialised.")

    query = db.collection("tasks").where("owner_uid", "==", uid)
    docs = query.stream()

    tasks = []
    for doc in docs:
        data = doc.to_dict()
        data["id"] = doc.id
        tasks.append(TaskResponse(**data))

    # Apply filters
    if status == "completed":
        tasks = [t for t in tasks if t.completed]
    elif status == "pending":
        tasks = [t for t in tasks if not t.completed]

    if priority:
        tasks = [t for t in tasks if t.priority == priority]

    # Sort
    reverse = order.lower() == "desc"
    tasks.sort(key=lambda t: getattr(t, sort_by, "") or "", reverse=reverse)

    # Paginate
    start = (page - 1) * page_size
    return tasks[start:start + page_size]


@router.post("/", response_model=TaskResponse, status_code=201, summary="Create a new task")
async def create_task(body: TaskCreateRequest, decoded_token: dict = Depends(verify_token)):
    uid = decoded_token.get("uid")

    if db is None:
        raise HTTPException(status_code=503, detail="Firestore not initialised.")

    now = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    task_data = {
        "title": body.title,
        "description": body.description,
        "completed": False,
        "created_at": now,
        "owner_uid": uid,
        "priority": body.priority,
        "deadline": body.deadline,
    }

    doc_ref = db.collection("tasks").document()
    doc_ref.set(task_data)

    return TaskResponse(id=doc_ref.id, **task_data)


@router.get("/{task_id}", response_model=TaskResponse, summary="Get a single task by ID")
async def get_task(task_id: str, decoded_token: dict = Depends(verify_token)):
    uid = decoded_token.get("uid")

    if db is None:
        raise HTTPException(status_code=503, detail="Firestore not initialised.")

    doc = db.collection("tasks").document(task_id).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail=f"Task '{task_id}' not found.")

    data = doc.to_dict()
    if data.get("owner_uid") != uid:
        raise HTTPException(status_code=403, detail="Not authorised to access this task.")

    data["id"] = doc.id
    return TaskResponse(**data)


@router.put("/{task_id}", response_model=TaskResponse, summary="Update a task")
async def update_task(task_id: str, body: TaskUpdateRequest, decoded_token: dict = Depends(verify_token)):
    uid = decoded_token.get("uid")

    if db is None:
        raise HTTPException(status_code=503, detail="Firestore not initialised.")

    doc_ref = db.collection("tasks").document(task_id)
    doc = doc_ref.get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail=f"Task '{task_id}' not found.")

    data = doc.to_dict()
    if data.get("owner_uid") != uid:
        raise HTTPException(status_code=403, detail="Not authorised to update this task.")

    updates = body.model_dump(exclude_unset=True)
    doc_ref.update(updates)

    data.update(updates)
    data["id"] = task_id
    return TaskResponse(**data)


@router.delete("/{task_id}", status_code=204, summary="Delete a task")
async def delete_task(task_id: str, decoded_token: dict = Depends(verify_token)):
    uid = decoded_token.get("uid")

    if db is None:
        raise HTTPException(status_code=503, detail="Firestore not initialised.")

    doc_ref = db.collection("tasks").document(task_id)
    doc = doc_ref.get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail=f"Task '{task_id}' not found.")

    data = doc.to_dict()
    if data.get("owner_uid") != uid:
        raise HTTPException(status_code=403, detail="Not authorised to delete this task.")

    doc_ref.delete()
    return None
