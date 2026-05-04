"""
core/firebase.py
----------------
Initialises the Firebase Admin SDK once and exposes a shared Firestore client.

Usage:
    from core.firebase import db
    doc = db.collection("tasks").document("some_id").get()

NOTE: If FIREBASE_SERVICE_ACCOUNT is not set in .env, Firebase will not be
initialised and `db` will be None. The server will still start and Swagger UI
will work — stubs will function normally. Set the credential before connecting
real Firestore reads/writes.
"""

import os
import warnings
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

db = None  # Will be set to a Firestore client once credentials are available.


def _init_firebase():
    """Initialise Firebase Admin SDK from the service account path in .env."""
    service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT")
    database_url = os.getenv("DATABASE_URL")

    if not service_account_path or service_account_path.startswith("path/to"):
        warnings.warn(
            "\n[Firebase] FIREBASE_SERVICE_ACCOUNT is not configured in .env.\n"
            "  → The server will start, but Firestore calls will not work.\n"
            "  → Set the path to your serviceAccountKey.json to enable Firebase.",
            stacklevel=2,
        )
        return None

    try:
        cred = credentials.Certificate(service_account_path)
        app = firebase_admin.initialize_app(
            cred,
            {"databaseURL": database_url} if database_url else {},
        )
        return firestore.client()
    except Exception as e:
        warnings.warn(f"[Firebase] Initialisation failed: {e}", stacklevel=2)
        return None


# Initialise once at import time
if not firebase_admin._apps:
    db = _init_firebase()
else:
    db = firestore.client()
