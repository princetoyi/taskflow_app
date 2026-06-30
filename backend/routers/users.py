"""
routers/users.py
----------------
Router for /users endpoints using real Firestore reads/writes.
Includes theme preferences and role (manager/worker).
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Literal
from core.security import verify_token
from core.firebase import db

router = APIRouter(prefix="/users", tags=["users"])


# ── Schemas ───────────────────────────────────────────────────────────────────

class UserPreferences(BaseModel):
    theme: Literal["light", "dark"] = "light"
    role: Literal["manager", "worker"] = "worker"


class UserProfileResponse(BaseModel):
    uid: str
    email: str
    display_name: str | None = None
    role: Literal["manager", "worker"] = "worker"
    theme: Literal["light", "dark"] = "light"


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/preferences", response_model=UserPreferences, summary="Get user theme and role")
async def get_preferences(decoded_token: dict = Depends(verify_token)):
    uid = decoded_token.get("uid")

    if db is None:
        raise HTTPException(status_code=503, detail="Firestore not initialised.")

    doc = db.collection("users").document(uid).get()
    if not doc.exists:
        # Return defaults for new users
        return UserPreferences(theme="light", role="worker")

    data = doc.to_dict()
    return UserPreferences(
        theme=data.get("theme", "light"),
        role=data.get("role", "worker"),
    )


@router.put("/preferences", response_model=UserPreferences, summary="Update user theme and role")
async def update_preferences(body: UserPreferences, decoded_token: dict = Depends(verify_token)):
    uid = decoded_token.get("uid")

    if db is None:
        raise HTTPException(status_code=503, detail="Firestore not initialised.")

    db.collection("users").document(uid).set(
        {"theme": body.theme, "role": body.role},
        merge=True
    )
    return body


@router.get("/me", response_model=UserProfileResponse, summary="Get full user profile including role")
async def get_me(decoded_token: dict = Depends(verify_token)):
    uid = decoded_token.get("uid")
    email = decoded_token.get("email", "")
    display_name = decoded_token.get("name")

    if db is None:
        raise HTTPException(status_code=503, detail="Firestore not initialised.")

    doc = db.collection("users").document(uid).get()
    role = "worker"
    theme = "light"

    if doc.exists:
        data = doc.to_dict()
        role = data.get("role", "worker")
        theme = data.get("theme", "light")

    return UserProfileResponse(
        uid=uid,
        email=email,
        display_name=display_name,
        role=role,
        theme=theme,
    )