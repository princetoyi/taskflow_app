# app/services/notification_service.py
# Handles FCM push notifications and notification records in Firestore.
# Called by the scheduler for deadline reminders and directly by routes.

from datetime import datetime
from firebase_admin import messaging, firestore

NOTIFICATIONS_COLLECTION = "notifications"
USERS_COLLECTION = "users"


def get_db():
    return firestore.client()


def send_push_notification(fcm_token: str, title: str, body: str) -> bool:
    # Send a push notification to a single device via FCM
    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            token=fcm_token,
        )
        messaging.send(message)
        return True
    except Exception as e:
        print(f"FCM send failed: {e}")
        return False


def save_notification(uid: str, task_id: str, message: str, type: str) -> None:
    # Write a notification record to Firestore
    # Fields: user_id, task_id, message, type, is_read, created_at
    db = get_db()
    db.collection(NOTIFICATIONS_COLLECTION).add({
        "user_id": uid,
        "task_id": task_id,
        "message": message,
        "type": type,
        "is_read": False,
        "created_at": datetime.utcnow().isoformat(),
    })


def update_fcm_token(uid: str, fcm_token: str) -> None:
    # Store the latest FCM device token in the user's Firestore document.
    # Called on every login so the token stays current.
    db = get_db()
    db.collection(USERS_COLLECTION).document(uid).set(
        {"fcm_token": fcm_token},
        merge=True
    )


def send_deadline_reminders() -> None:
    # Scheduled job — runs periodically via APScheduler.
    # Finds tasks due within 24 hours and sends a push notification to the owner.
    db = get_db()
    now = datetime.utcnow()

    tasks = db.collection("tasks").stream()

    for task in tasks:
        data = task.to_dict()

        if data.get("completed"):
            continue

        deadline_str = data.get("deadline")
        if not deadline_str:
            continue

        try:
            deadline = datetime.fromisoformat(deadline_str.replace("Z", ""))
        except ValueError:
            continue

        hours_left = (deadline - now).total_seconds() / 3600

        # Notify if task is due within 24 hours but not already overdue
        if 0 < hours_left <= 24:
            uid = data.get("owner_uid")
            if not uid:
                continue

            # Get the user's FCM token from Firestore
            user_doc = db.collection("users").document(uid).get()
            if not user_doc.exists:
                continue

            fcm_token = user_doc.to_dict().get("fcm_token")
            if not fcm_token:
                continue

            title = "Task Deadline Reminder"
            body = f"'{data.get('title')}' is due in {int(hours_left)} hour(s)."

            sent = send_push_notification(fcm_token, title, body)

            if sent:
                save_notification(
                    uid=uid,
                    task_id=task.id,
                    message=body,
                    type="deadline_reminder"
                )