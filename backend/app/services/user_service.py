# app/services/user_service.py
# User profile, directory, and account-management operations —
# backs the /users routes beyond the plain theme preferences.

import os
from datetime import datetime

from fastapi import HTTPException
from firebase_admin import auth, firestore, storage

from app.services.auth_service import ensure_user_profile, verify_password

USERS_COLLECTION = "users"


def get_db():
    return firestore.client()


def get_own_profile(uid: str, email: str, display_name: str | None) -> dict:
    return ensure_user_profile(uid, email, display_name)


def get_user(user_id: str) -> dict | None:
    doc = get_db().collection(USERS_COLLECTION).document(user_id).get()
    return doc.to_dict() if doc.exists else None


def list_users(
    role: str | None = None,
    is_active: bool | None = None,
    page: int = 1,
    page_size: int = 20,
) -> list[dict]:
    # Equality-only filters — Firestore can merge these from single-field
    # indexes without needing a composite index, unlike the tasks queries.
    query = get_db().collection(USERS_COLLECTION)
    if role is not None:
        query = query.where("role", "==", role)
    if is_active is not None:
        query = query.where("is_active", "==", is_active)

    offset = (page - 1) * page_size
    docs = query.limit(page_size).offset(offset).stream()
    return [doc.to_dict() for doc in docs]


def update_own_profile(uid: str, updates: dict) -> dict:
    if not updates:
        raise HTTPException(status_code=400, detail="No updates provided")
    updates["updated_at"] = datetime.utcnow().isoformat()
    doc_ref = get_db().collection(USERS_COLLECTION).document(uid)
    doc_ref.set(updates, merge=True)
    return doc_ref.get().to_dict()


def update_user_admin(user_id: str, updates: dict) -> dict | None:
    doc_ref = get_db().collection(USERS_COLLECTION).document(user_id)
    if not doc_ref.get().exists:
        return None
    if not updates:
        raise HTTPException(status_code=400, detail="No updates provided")
    updates["updated_at"] = datetime.utcnow().isoformat()
    doc_ref.set(updates, merge=True)
    return doc_ref.get().to_dict()


def upload_profile_image(uid: str, contents: bytes, content_type: str, filename: str) -> dict:
    bucket_name = os.environ.get("FIREBASE_STORAGE_BUCKET")
    bucket = storage.bucket(bucket_name) if bucket_name else storage.bucket()

    blob = bucket.blob(f"profile_images/{uid}/{filename}")
    blob.upload_from_string(contents, content_type=content_type)
    # Requires the service account to have Storage Object Admin (or equivalent)
    # on the bucket — otherwise this raises and the image URL never gets saved.
    blob.make_public()

    return update_own_profile(uid, {"profile_image_url": blob.public_url})


async def change_password(uid: str, email: str, current_password: str, new_password: str) -> None:
    await verify_password(email, current_password)
    auth.update_user(uid, password=new_password)


def delete_user(user_id: str) -> None:
    try:
        auth.delete_user(user_id)
    except auth.UserNotFoundError:
        pass
    get_db().collection(USERS_COLLECTION).document(user_id).delete()
