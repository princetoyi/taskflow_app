# app/routes/tasks.py
# Task CRUD routes — all protected by JWT middleware.
# Every operation is scoped to the authenticated user's UID.

from fastapi import APIRouter, Depends, Query
from app.models.task import TaskCreate, TaskUpdate, TaskResponse
from app.services import task_service
from app.middleware.auth_middleware import get_current_user

router = APIRouter()


@router.post("", response_model=TaskResponse)
async def create_task(
    data: TaskCreate,
    user: dict = Depends(get_current_user)
):
    return await task_service.create_task(uid=user["uid"], data=data)


@router.get("", response_model=list[TaskResponse])
async def get_tasks(
    status: str | None = Query(None, description="Filter: pending or completed"),
    priority: str | None = Query(None, description="Filter: low, medium, high"),
    sort_by: str = Query("created_at", description="Field to sort by"),
    order: str = Query("asc", description="asc or desc"),
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    user: dict = Depends(get_current_user)
):
    return await task_service.get_tasks(
        uid=user["uid"],
        status=status,
        priority=priority,
        sort_by=sort_by,
        order=order,
        page=page,
        page_size=page_size,
    )


@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(
    task_id: str,
    user: dict = Depends(get_current_user)
):
    return await task_service.get_task(uid=user["uid"], task_id=task_id)


@router.put("/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: str,
    data: TaskUpdate,
    user: dict = Depends(get_current_user)
):
    return await task_service.update_task(uid=user["uid"], task_id=task_id, data=data)


@router.delete("/{task_id}")
async def delete_task(
    task_id: str,
    user: dict = Depends(get_current_user)
):
    return await task_service.delete_task(uid=user["uid"], task_id=task_id)