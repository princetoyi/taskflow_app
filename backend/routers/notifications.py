"""
routers/notifications.py
------------------------
Router for /notifications endpoints.
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from core.security import verify_token

router = APIRouter(prefix="/notifications", tags=["notifications"])

class FCMTokenRequest(BaseModel):
    fcm_token: str

class NotificationResponse(BaseModel):
    id: str
    title: str
    body: str
    created_at: str
    is_read: bool

# In-memory FCM tokens
FCM_TOKENS = {}

# Stub notification data
STUB_NOTIFICATIONS = [
    NotificationResponse(
        id="notif-001",
        title="Welcome to TaskFlow!",
        body="Stay organized and track your tasks efficiently.",
        created_at="2026-06-10T10:00:00Z",
        is_read=False
    ),
    NotificationResponse(
        id="notif-002",
        title="Task Overdue",
        body="Your task 'Set up Firebase project' is due soon.",
        created_at="2026-06-10T12:00:00Z",
        is_read=True
    )
]

@router.post("/fcm-token", summary="Update Firebase Cloud Messaging token")
async def update_fcm_token(body: FCMTokenRequest, decoded_token: dict = Depends(verify_token)):
    uid = decoded_token.get("uid") or "stub-uid-001"
    FCM_TOKENS[uid] = body.fcm_token
    return {"message": "FCM token updated successfully"}

@router.get("/", response_model=list[NotificationResponse], summary="Get notifications for authenticated user")
async def get_notifications(decoded_token: dict = Depends(verify_token)):
    return STUB_NOTIFICATIONS

@router.put("/{notification_id}/read", response_model=NotificationResponse, summary="Mark notification as read")
async def mark_notification_as_read(notification_id: str, decoded_token: dict = Depends(verify_token)):
    notif = next((n for n in STUB_NOTIFICATIONS if n.id == notification_id), None)
    if not notif:
        raise HTTPException(status_code=404, detail=f"Notification '{notification_id}' not found.")
    
    updated_notif = notif.model_copy(update={"is_read": True})
    idx = STUB_NOTIFICATIONS.index(notif)
    STUB_NOTIFICATIONS[idx] = updated_notif
    return updated_notif
