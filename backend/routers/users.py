"""
routers/users.py
----------------
User and team management endpoints.
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from typing import Optional
from core.security import verify_token
from app.repositories import UserRepository, TaskRepository

router = APIRouter(prefix="/users", tags=["users"])


# ── Response schemas ──────────────────────────────────────────────────────────

class UserResponse:
    def __init__(self, uid: str, email: str, display_name: str | None, role: str):
        self.uid = uid
        self.email = email
        self.display_name = display_name
        self.role = role
    
    def to_dict(self):
        return {
            "uid": self.uid,
            "email": self.email,
            "display_name": self.display_name,
            "role": self.role,
        }


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/me", summary="Get current user profile")
async def get_current_user(decoded_token: dict = Depends(verify_token)):
    """
    Returns the current authenticated user's profile.
    """
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    try:
        user = UserRepository.get_user(uid)
        if not user:
            raise HTTPException(status_code=404, detail="User profile not found")
        
        # Return safe user information (don't expose internal IDs)
        return {
            "uid": user.get("uid"),
            "email": user.get("email"),
            "display_name": user.get("display_name"),
            "role": user.get("role"),
            "is_active": user.get("is_active"),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/team", summary="Get team members (Manager only)")
async def get_team(decoded_token: dict = Depends(verify_token)):
    """
    Returns all team members. Only managers and admins can access this.
    """
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    try:
        # Check if user is a manager or admin
        user = UserRepository.get_user(uid)
        if not user or user.get("role") not in ["manager", "admin"]:
            raise HTTPException(status_code=403, detail="Only managers can view team members")
        
        # Get all team members
        team_members = UserRepository.get_team_members(uid)
        
        return [
            {
                "uid": member.get("uid"),
                "email": member.get("email"),
                "display_name": member.get("display_name"),
                "role": member.get("role"),
            }
            for member in team_members
        ]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/team/{user_id}/tasks", summary="Get team member's tasks (Manager only)")
async def get_team_member_tasks(
    user_id: str,
    decoded_token: dict = Depends(verify_token),
    status: Optional[str] = Query(None),
):
    """
    Returns tasks for a specific team member. Only managers and admins can access.
    """
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    try:
        # Check if user is a manager or admin
        user = UserRepository.get_user(uid)
        if not user or user.get("role") not in ["manager", "admin"]:
            raise HTTPException(status_code=403, detail="Only managers can view team member tasks")
        
        # Get tasks for the team member
        tasks = TaskRepository.get_user_tasks(
            owner_uid=user_id,
            status=status,
            page_size=100
        )
        
        return [
            {
                "id": task.get("id"),
                "title": task.get("title"),
                "description": task.get("description"),
                "completed": task.get("completed"),
                "priority": task.get("priority"),
                "deadline": task.get("deadline"),
                "created_at": task.get("created_at"),
            }
            for task in tasks
        ]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/statistics", summary="Get user task statistics")
async def get_user_statistics(
    user_id: str,
    decoded_token: dict = Depends(verify_token),
):
    """
    Returns task statistics for a user.
    Users can only view their own stats, managers can view team members' stats.
    """
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    # Check permission
    if uid != user_id:
        user = UserRepository.get_user(uid)
        if not user or user.get("role") not in ["manager", "admin"]:
            raise HTTPException(status_code=403, detail="Forbidden")
    
    try:
        stats = TaskRepository.get_task_statistics(user_id)
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/me", summary="Update current user profile")
async def update_current_user(
    decoded_token: dict = Depends(verify_token),
    display_name: Optional[str] = None,
):
    """
    Update current user's profile.
    """
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    try:
        updates = {}
        if display_name is not None:
            updates["display_name"] = display_name
        
        if not updates:
            raise HTTPException(status_code=400, detail="No updates provided")
        
        user = UserRepository.update_user(uid, **updates)
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        return {
            "uid": user.get("uid"),
            "email": user.get("email"),
            "display_name": user.get("display_name"),
            "role": user.get("role"),
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
