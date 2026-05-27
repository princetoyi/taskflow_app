# app/models/task.py
# Pydantic models for task request validation and API responses.

from pydantic import BaseModel
from datetime import datetime
from typing import Literal


class TaskCreate(BaseModel):
    title: str
    description: str | None = None
    priority: Literal["low", "medium", "high"] = "medium"
    deadline: datetime | None = None


class TaskUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    completed: bool | None = None
    priority: Literal["low", "medium", "high"] | None = None
    deadline: datetime | None = None


class TaskResponse(BaseModel):
    id: str
    owner_uid: str
    title: str
    description: str | None = None
    completed: bool
    priority: str
    deadline: str | None = None
    created_at: str