# app/routes/users.py
# User preference, profile, and directory routes.
# All routes protected by JWT middleware.
#
# Route order matters here: literal paths (/preferences, /profile, the
# list route) must be declared before /{user_id}, otherwise FastAPI would
# match e.g. GET /users/profile against /{user_id} with user_id="profile".

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from pydantic import BaseModel
from firebase_admin import firestore

from app.middleware.auth_middleware import get_current_user
from app.models.user import (
    ChangePasswordRequest,
    UserAdminUpdateRequest,
    UserProfileDetail,
    UserProfileUpdateRequest,
)
from app.services import user_service

router = APIRouter()

USERS_COLLECTION = "users"


class ThemePreference(BaseModel):
    theme: str  # "light" or "dark"


def _require_admin(user: dict) -> dict:
    profile = user_service.get_own_profile(user["uid"], user.get("email", ""), user.get("name"))
    if profile.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return profile


@router.get("/preferences")
async def get_preferences(user: dict = Depends(get_current_user)):
    # Retrieve user preferences from Firestore
    db = firestore.client()
    doc = db.collection(USERS_COLLECTION).document(user["uid"]).get()

    if not doc.exists:
        return {"theme": "light"}  # Default theme

    return doc.to_dict()


@router.put("/preferences")
async def update_preferences(
    data: ThemePreference,
    user: dict = Depends(get_current_user)
):
    # Save theme preference to Firestore user document
    db = firestore.client()
    db.collection(USERS_COLLECTION).document(user["uid"]).set(
        {"theme": data.theme},
        merge=True  # Don't overwrite other fields
    )
    return {"message": "Preferences updated", "theme": data.theme}


@router.get("/profile", response_model=UserProfileDetail)
async def get_profile(user: dict = Depends(get_current_user)):
    profile = user_service.get_own_profile(user["uid"], user.get("email", ""), user.get("name"))
    return UserProfileDetail(**profile)


@router.patch("/profile", response_model=UserProfileDetail)
async def update_profile(data: UserProfileUpdateRequest, user: dict = Depends(get_current_user)):
    updated = user_service.update_own_profile(user["uid"], data.model_dump(exclude_none=True))
    return UserProfileDetail(**updated)


@router.post("/profile/image", response_model=UserProfileDetail)
async def upload_profile_image(image: UploadFile = File(...), user: dict = Depends(get_current_user)):
    contents = await image.read()
    updated = user_service.upload_profile_image(
        user["uid"], contents, image.content_type or "image/jpeg", image.filename or "profile.jpg"
    )
    return UserProfileDetail(**updated)


@router.post("/profile/change-password")
async def change_password(data: ChangePasswordRequest, user: dict = Depends(get_current_user)):
    await user_service.change_password(user["uid"], user.get("email", ""), data.current_password, data.new_password)
    return {"message": "Password changed successfully"}


@router.get("", response_model=list[UserProfileDetail])
async def list_users(
    role: str | None = Query(None),
    is_active: bool | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: dict = Depends(get_current_user),
):
    _require_admin(user)
    users = user_service.list_users(role=role, is_active=is_active, page=page, page_size=page_size)
    return [UserProfileDetail(**u) for u in users]


@router.get("/{user_id}", response_model=UserProfileDetail)
async def get_user(user_id: str, user: dict = Depends(get_current_user)):
    if user_id != user["uid"]:
        _require_admin(user)
    profile = user_service.get_user(user_id)
    if not profile:
        raise HTTPException(status_code=404, detail="User not found")
    return UserProfileDetail(**profile)


@router.patch("/{user_id}", response_model=UserProfileDetail)
async def update_user(user_id: str, data: UserAdminUpdateRequest, user: dict = Depends(get_current_user)):
    _require_admin(user)
    updated = user_service.update_user_admin(user_id, data.model_dump(exclude_none=True))
    if not updated:
        raise HTTPException(status_code=404, detail="User not found")
    return UserProfileDetail(**updated)


@router.delete("/{user_id}", status_code=204)
async def delete_user(user_id: str, user: dict = Depends(get_current_user)):
    _require_admin(user)
    if user_id == user["uid"]:
        raise HTTPException(status_code=400, detail="Cannot delete your own account")
    user_service.delete_user(user_id)
