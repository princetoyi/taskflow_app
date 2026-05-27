# app/firebase_config.py
# Initialises the Firebase Admin SDK once at startup (called from main.py).
# Place serviceAccountKey.json in backend/ and add it to .gitignore — never commit it.

import os
import logging
import firebase_admin
from firebase_admin import credentials

logger = logging.getLogger(__name__)

# Resolves to backend/ regardless of where uvicorn is launched from.
# Structure: __file__ = backend/app/firebase_config.py → up two levels = backend/
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Default key location: backend/serviceAccountKey.json
# Override by setting FIREBASE_SERVICE_ACCOUNT_PATH in .env
DEFAULT_SERVICE_ACCOUNT_PATH = os.path.join(BASE_DIR, "serviceAccountKey.json")


def initialize_firebase() -> None:
    # Guard against initialising twice — Firebase Admin SDK raises if called again
    if firebase_admin._apps:
        logger.info("Firebase already initialised — skipping")
        return

    # Use .env override if set, otherwise fall back to default path
    service_account_path = os.environ.get(
        "FIREBASE_SERVICE_ACCOUNT_PATH",
        DEFAULT_SERVICE_ACCOUNT_PATH
    )

    # Fail at startup so misconfiguration is caught early, not at first request
    if not os.path.exists(service_account_path):
        raise FileNotFoundError(
            f"Service account key not found at: {service_account_path}\n"
            "Fix: Download from Firebase Console → Project Settings → Service Accounts\n"
            f"and place it in: {BASE_DIR}"
        )

    cred = credentials.Certificate(service_account_path)
    firebase_admin.initialize_app(cred)
    logger.info(f"Firebase Admin SDK initialised — {service_account_path}")
    