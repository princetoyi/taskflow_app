"""
routers/tasks.py
----------------
Stub router for /tasks endpoints.
Real implementation will read/write to Cloud Firestore via firebase-admin.
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from datetime import datetime
from core.security import verify_token

router = APIRouter(prefix="/tasks", tags=["tasks"])


# ── Request / Response schemas ────────────────────────────────────────────────

class TaskCreateRequest(BaseModel):
    title: str
    description: str = ""


class TaskUpdateRequest(BaseModel):
    title: str | None = None
    description: str | None = None
    is_completed: bool | None = None


class TaskResponse(BaseModel):
    id: str
    title: str
    description: str
    is_completed: bool
    created_at: str
    user_id: str


# ── Stub data ─────────────────────────────────────────────────────────────────

STUB_TASKS = [
    TaskResponse(
        id="task-001",
        title="Set up Firebase project",
        description="Enable Auth and Firestore, export service account JSON.",
        is_completed=True,
        created_at="2026-05-01T08:00:00Z",
        user_id="stub-uid-001",
    ),
    TaskResponse(
        id="task-002",
        title="Build FastAPI backend scaffold",
        description="Create routers, firebase init, and CORS middleware.",
        is_completed=False,
        created_at="2026-05-02T09:00:00Z",
        user_id="stub-uid-001",
    ),
]


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/", response_model=list[TaskResponse], summary="Get all tasks for authenticated user")
async def get_tasks(decoded_token: dict = Depends(verify_token)):
    """
    STUB — Returns hardcoded task list.
    """
    uid = decoded_token.get("uid")
    # In a real implementation: filter by user_id
    return STUB_TASKS


@router.post("/", response_model=TaskResponse, status_code=201, summary="Create a new task")
async def create_task(body: TaskCreateRequest, decoded_token: dict = Depends(verify_token)):
    """
    STUB — Returns a fake created task.
    """
    uid = decoded_token.get("uid")
    return TaskResponse(
        id="task-new-stub",
        title=body.title,
        description=body.description,
        is_completed=False,
        created_at=datetime.utcnow().isoformat() + "Z",
        user_id=uid or "stub-uid-001",
    )


@router.get("/{task_id}", response_model=TaskResponse, summary="Get a single task by ID")
async def get_task(task_id: str, decoded_token: dict = Depends(verify_token)):
    """STUB — Returns the first stub task regardless of ID."""
    task = next((t for t in STUB_TASKS if t.id == task_id), None)
    if not task:
        raise HTTPException(status_code=404, detail=f"Task '{task_id}' not found.")
    return task


@router.patch("/{task_id}", response_model=TaskResponse, summary="Update a task")
async def update_task(task_id: str, body: TaskUpdateRequest, decoded_token: dict = Depends(verify_token)):
    """STUB — Returns the first stub task with patched fields applied."""
    task = next((t for t in STUB_TASKS if t.id == task_id), None)
    if not task:
        raise HTTPException(status_code=404, detail=f"Task '{task_id}' not found.")
    updated = task.model_copy(update=body.model_dump(exclude_none=True))
    return updated


@router.delete("/{task_id}", status_code=204, summary="Delete a task")
async def delete_task(task_id: str, decoded_token: dict = Depends(verify_token)):
    """STUB — No-op delete."""
    return None
