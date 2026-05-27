# app/routes/users.py
# User preference routes — theme, settings, and profile data.
# All routes protected by JWT middleware.

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from firebase_admin import firestore
from app.middleware.auth_middleware import get_current_user

router = APIRouter()

USERS_COLLECTION = "users"


class ThemePreference(BaseModel):
    theme: str  # "light" or "dark"


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