"""
routers/tasks.py
----------------
Stub router for /tasks endpoints.
Real implementation will read/write to Cloud Firestore via firebase-admin.
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from datetime import datetime, timezone
from core.security import verify_token

router = APIRouter(prefix="/tasks", tags=["tasks"])


from typing import Literal
from fastapi import Query

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


# ── Stub data ─────────────────────────────────────────────────────────────────

STUB_TASKS = [
    TaskResponse(
        id="task-001",
        title="Set up Firebase project",
        description="Enable Auth and Firestore, export service account JSON.",
        completed=True,
        created_at="2026-05-01T08:00:00Z",
        owner_uid="stub-uid-001",
        priority="high",
        deadline=None,
    ),
    TaskResponse(
        id="task-002",
        title="Build FastAPI backend scaffold",
        description="Create routers, firebase init, and CORS middleware.",
        completed=False,
        created_at="2026-05-02T09:00:00Z",
        owner_uid="stub-uid-001",
        priority="medium",
        deadline=None,
    ),
]


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
    """
    STUB — Returns filtered, sorted, and paginated task list.
    """
    uid = decoded_token.get("uid") or "stub-uid-001"
    
    # In a real implementation: filter by owner_uid
    tasks = list(STUB_TASKS)
    
    # Apply optional filters
    if status is not None:
        if status == "completed":
            tasks = [t for t in tasks if t.completed]
        elif status == "pending":
            tasks = [t for t in tasks if not t.completed]

    if priority is not None:
        tasks = [t for t in tasks if t.priority == priority]

    # Apply sorting
    reverse = (order.lower() == "desc")
    def sort_key(task: TaskResponse):
        val = getattr(task, sort_by, None)
        return val if val is not None else ""

    try:
        tasks.sort(key=sort_key, reverse=reverse)
    except Exception:
        tasks.sort(key=lambda t: t.created_at, reverse=reverse)

    # Apply pagination
    start = (page - 1) * page_size
    end = start + page_size
    tasks = tasks[start:end]

    return tasks


@router.post("/", response_model=TaskResponse, status_code=201, summary="Create a new task")
async def create_task(body: TaskCreateRequest, decoded_token: dict = Depends(verify_token)):
    """
    STUB — Returns a fake created task and appends to in-memory list.
    """
    uid = decoded_token.get("uid") or "stub-uid-001"
    new_task = TaskResponse(
        id=f"task-new-{len(STUB_TASKS) + 1}",
        title=body.title,
        description=body.description,
        completed=False,
        created_at=datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        owner_uid=uid,
        priority=body.priority,
        deadline=body.deadline
    )
    STUB_TASKS.append(new_task)
    return new_task


@router.get("/{task_id}", response_model=TaskResponse, summary="Get a single task by ID")
async def get_task(task_id: str, decoded_token: dict = Depends(verify_token)):
    """STUB — Returns the task by ID."""
    task = next((t for t in STUB_TASKS if t.id == task_id), None)
    if not task:
        raise HTTPException(status_code=404, detail=f"Task '{task_id}' not found.")
    return task


@router.put("/{task_id}", response_model=TaskResponse, summary="Update a task")
async def update_task(task_id: str, body: TaskUpdateRequest, decoded_token: dict = Depends(verify_token)):
    """STUB — Returns the updated task with put fields applied."""
    global STUB_TASKS
    task_idx = next((i for i, t in enumerate(STUB_TASKS) if t.id == task_id), None)
    if task_idx is None:
        raise HTTPException(status_code=404, detail=f"Task '{task_id}' not found.")
    
    task = STUB_TASKS[task_idx]
    
    # Exclude unset fields (partial updates supported)
    updates = body.model_dump(exclude_unset=True)
    updated_dict = task.model_dump()
    for k, v in updates.items():
        updated_dict[k] = v
        
    updated_task = TaskResponse(**updated_dict)
    STUB_TASKS[task_idx] = updated_task
    return updated_task


@router.delete("/{task_id}", status_code=204, summary="Delete a task")
async def delete_task(task_id: str, decoded_token: dict = Depends(verify_token)):
    """STUB — Delete a task from the in-memory list."""
    global STUB_TASKS
    task_idx = next((i for i, t in enumerate(STUB_TASKS) if t.id == task_id), None)
    if task_idx is None:
        raise HTTPException(status_code=404, detail=f"Task '{task_id}' not found.")
    STUB_TASKS.pop(task_idx)
    return None
