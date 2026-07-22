# app/services/auth_service.py
# Handles Firebase Auth operations — signup and login.
# Login uses the Firebase REST API since the Admin SDK is server-side only
# and does not expose a password-based sign-in method.

import os
from datetime import datetime

import httpx
from firebase_admin import auth, firestore
from fastapi import HTTPException
from app.models.user import SignupRequest, LoginRequest, AuthResponse, UserProfileResponse

# Firebase REST API endpoint for email/password sign-in.
# Requires your Firebase Web API key — add FIREBASE_WEB_API_KEY to .env
FIREBASE_SIGN_IN_URL = (
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
)

USERS_COLLECTION = "users"


def ensure_user_profile(uid: str, email: str, display_name: str | None, role: str = "employee") -> dict:
    # Create the Firestore profile doc if it doesn't exist yet (new signup,
    # or a user that existed in Firebase Auth before this doc was introduced).
    # `role` only applies at creation — an existing profile's role is never
    # touched here, so this can't be used to change someone's role later.
    db = firestore.client()
    doc_ref = db.collection(USERS_COLLECTION).document(uid)
    doc = doc_ref.get()
    if doc.exists:
        return doc.to_dict()

    profile = {
        "uid": uid,
        "email": email,
        "display_name": display_name,
        "role": role,
        "is_active": True,
        "created_at": datetime.utcnow().isoformat(),
    }
    doc_ref.set(profile)
    return profile


async def signup(request: SignupRequest) -> AuthResponse:
    try:
        # Create user in Firebase Auth
        user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=request.display_name,
        )
        ensure_user_profile(user.uid, user.email, user.display_name, role=request.role)

        # Generate a custom token so the client can sign in immediately
        token = auth.create_custom_token(user.uid).decode("utf-8")

        return AuthResponse(
            uid=user.uid,
            email=user.email,
            display_name=user.display_name,
            token=token,
        )
    except Exception as e:
        if "EMAIL_EXISTS" in str(e) or "already exists" in str(e).lower():
            raise HTTPException(status_code=400, detail="Email already registered")
        raise HTTPException(status_code=500, detail=str(e))


async def verify_password(email: str, password: str) -> dict:
    # Shared by login() and the change-password flow — the Admin SDK has no
    # way to verify a plaintext password itself, so both go through the same
    # Identity Toolkit REST sign-in call.
    api_key = os.environ.get("FIREBASE_WEB_API_KEY") or os.environ.get("FIREBASE_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="FIREBASE_WEB_API_KEY (or FIREBASE_API_KEY) not set in .env")

    async with httpx.AsyncClient() as client:
        response = await client.post(
            FIREBASE_SIGN_IN_URL,
            params={"key": api_key},
            json={
                "email": email,
                "password": password,
                "returnSecureToken": True,
            },
        )

    if response.status_code != 200:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    return response.json()


async def login(request: LoginRequest) -> AuthResponse:
    data = await verify_password(request.email, request.password)
    ensure_user_profile(data["localId"], data["email"], data.get("displayName"))

    return AuthResponse(
        uid=data["localId"],
        email=data["email"],
        display_name=data.get("displayName"),
        token=data["idToken"],
    )


async def get_current_user_profile(
    uid: str, email: str, display_name: str | None, role: str = "employee"
) -> UserProfileResponse:
    profile = ensure_user_profile(uid, email, display_name, role=role)
    return UserProfileResponse(
        uid=profile["uid"],
        email=profile["email"],
        display_name=profile.get("display_name"),
        role=profile.get("role", "employee"),
        is_active=profile.get("is_active", True),
    )


async def logout() -> dict:
    # Firebase ID tokens are stateless — there is nothing to invalidate
    # server-side. The client discards its token and, if desired, calls
    # firebase_admin.auth.revoke_refresh_tokens(uid) to force re-authentication
    # on other devices. This endpoint exists so the client has a symmetric
    # call to make and a place to hook that in later.
    return {"message": "Logged out"}