"""
routers/tasks.py
----------------
Task management endpoints with Firestore integration.
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from core.security import verify_token
from app.repositories import TaskRepository
from app.models.task import TaskCreate, TaskUpdate, TaskResponse

router = APIRouter(prefix="/tasks", tags=["tasks"])


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/", response_model=list[TaskResponse], summary="Get all tasks for authenticated user")
async def get_tasks(
    decoded_token: dict = Depends(verify_token),
    status: Optional[str] = Query(None),
    priority: Optional[str] = Query(None),
    sort_by: str = Query("created_at"),
    order: str = Query("desc"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    """
    Get all tasks for the authenticated user with optional filtering and sorting.
    
    Query Parameters:
    - status: Filter by "completed" or "pending"
    - priority: Filter by "low", "medium", or "high"
    - sort_by: Sort by "created_at", "deadline", or "title"
    - order: Sort order "asc" or "desc"
    - page: Page number (1-indexed)
    - page_size: Items per page
    """
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    try:
        tasks = TaskRepository.get_user_tasks(
            owner_uid=uid,
            status=status,
            priority=priority,
            sort_by=sort_by,
            order=order,
            page=page,
            page_size=page_size,
        )
        
        # Convert to response format
        return [
            TaskResponse(
                id=task["id"],
                owner_uid=task["owner_uid"],
                title=task["title"],
                description=task.get("description"),
                completed=task.get("completed", False),
                priority=task.get("priority", "medium"),
                deadline=task.get("deadline"),
                created_at=task.get("created_at", datetime.utcnow().isoformat() + "Z"),
            )
            for task in tasks
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/", response_model=TaskResponse, status_code=201, summary="Create a new task")
async def create_task(body: TaskCreate, decoded_token: dict = Depends(verify_token)):
    """Create a new task for the authenticated user."""
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    try:
        task = TaskRepository.create_task(
            owner_uid=uid,
            title=body.title,
            description=body.description,
            priority=body.priority,
            deadline=body.deadline.isoformat() if body.deadline else None,
        )
        
        return TaskResponse(
            id=task["id"],
            owner_uid=task["owner_uid"],
            title=task["title"],
            description=task.get("description"),
            completed=task.get("completed", False),
            priority=task.get("priority", "medium"),
            deadline=task.get("deadline"),
            created_at=task.get("created_at", datetime.utcnow().isoformat() + "Z"),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{task_id}", response_model=TaskResponse, summary="Get a single task by ID")
async def get_task(task_id: str, decoded_token: dict = Depends(verify_token)):
    """Get a single task by ID."""
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    try:
        task = TaskRepository.get_task(task_id, uid)
        if not task:
            raise HTTPException(status_code=404, detail=f"Task '{task_id}' not found.")
        
        return TaskResponse(
            id=task["id"],
            owner_uid=task["owner_uid"],
            title=task["title"],
            description=task.get("description"),
            completed=task.get("completed", False),
            priority=task.get("priority", "medium"),
            deadline=task.get("deadline"),
            created_at=task.get("created_at", datetime.utcnow().isoformat() + "Z"),
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.patch("/{task_id}", response_model=TaskResponse, summary="Update a task")
async def update_task(task_id: str, body: TaskUpdate, decoded_token: dict = Depends(verify_token)):
    """Update a task."""
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    try:
        updates = {}
        
        if body.title is not None:
            updates["title"] = body.title
        if body.description is not None:
            updates["description"] = body.description
        if body.completed is not None:
            updates["completed"] = body.completed
        if body.priority is not None:
            updates["priority"] = body.priority
        if body.deadline is not None:
            updates["deadline"] = body.deadline.isoformat()
        
        task = TaskRepository.update_task(task_id, uid, **updates)
        
        if not task:
            raise HTTPException(status_code=404, detail=f"Task '{task_id}' not found.")
        
        return TaskResponse(
            id=task["id"],
            owner_uid=task["owner_uid"],
            title=task["title"],
            description=task.get("description"),
            completed=task.get("completed", False),
            priority=task.get("priority", "medium"),
            deadline=task.get("deadline"),
            created_at=task.get("created_at", datetime.utcnow().isoformat() + "Z"),
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{task_id}", status_code=204, summary="Delete a task")
async def delete_task(task_id: str, decoded_token: dict = Depends(verify_token)):
    """Delete a task."""
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    try:
        success = TaskRepository.delete_task(task_id, uid)
        if not success:
            raise HTTPException(status_code=404, detail=f"Task '{task_id}' not found.")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/statistics", summary="Get task statistics for a user")
async def get_task_statistics(user_id: str, decoded_token: dict = Depends(verify_token)):
    """Get task statistics (completed, pending, overdue, high priority count)."""
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    # Only allow users to get their own stats
    if uid != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    
    try:
        stats = TaskRepository.get_task_statistics(uid)
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
