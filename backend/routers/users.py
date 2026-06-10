"""
routers/users.py
----------------
Router for /users preferences endpoints.
"""

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Literal
from core.security import verify_token

router = APIRouter(prefix="/users", tags=["users"])

class UserPreferences(BaseModel):
    theme: Literal["light", "dark"]

# In-memory store for preferences
USER_PREFERENCES = {}

@router.get("/preferences", response_model=UserPreferences, summary="Get user theme preference")
async def get_preferences(decoded_token: dict = Depends(verify_token)):
    uid = decoded_token.get("uid") or "stub-uid-001"
    theme = USER_PREFERENCES.get(uid, "light")
    return UserPreferences(theme=theme)

@router.put("/preferences", response_model=UserPreferences, summary="Update user theme preference")
async def update_preferences(body: UserPreferences, decoded_token: dict = Depends(verify_token)):
    uid = decoded_token.get("uid") or "stub-uid-001"
    USER_PREFERENCES[uid] = body.theme
    return body
