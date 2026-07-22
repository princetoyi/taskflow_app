# app/routes/notifications.py
# Notification routes — fetch and mark notifications as read.
# FCM token update is also handled here on login.

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from firebase_admin import firestore
from app.middleware.auth_middleware import get_current_user

router = APIRouter()

NOTIFICATIONS_COLLECTION = "notifications"


class FCMTokenUpdate(BaseModel):
    fcm_token: str


@router.get("")
async def get_notifications(user: dict = Depends(get_current_user)):
    # Fetch all notifications for the logged-in user
    db = firestore.client()
    from google.cloud.firestore_v1 import FieldFilter
    docs = db.collection(NOTIFICATIONS_COLLECTION).where(
        filter=FieldFilter("user_id", "==", user["uid"])
    ).order_by("created_at", direction="DESCENDING").stream()

    return [doc.to_dict() | {"id": doc.id} for doc in docs]


@router.put("/{notification_id}/read")
async def mark_as_read(
    notification_id: str,
    user: dict = Depends(get_current_user)
):
    # Mark a single notification as read
    db = firestore.client()
    db.collection(NOTIFICATIONS_COLLECTION).document(notification_id).update(
        {"is_read": True}
    )
    return {"message": "Notification marked as read"}


@router.post("/fcm-token")
async def update_fcm_token(
    data: FCMTokenUpdate,
    user: dict = Depends(get_current_user)
):
    # Update FCM device token — called by Flutter on every login
    from app.services.notification_service import update_fcm_token
    update_fcm_token(uid=user["uid"], fcm_token=data.fcm_token)
    return {"message": "FCM token updated"}