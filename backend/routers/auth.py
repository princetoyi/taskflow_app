"""
routers/auth.py
---------------
Stub router for /auth endpoints.
Real implementation will verify Firebase ID tokens using firebase-admin.
"""

from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel

router = APIRouter(prefix="/auth", tags=["auth"])


# ── Request / Response schemas ────────────────────────────────────────────────

class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    uid: str
    email: str
    token: str


class UserProfileResponse(BaseModel):
    uid: str
    email: str
    display_name: str | None = None


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/login", response_model=TokenResponse, summary="Log in with email & password")
async def login(body: LoginRequest):
    """
    STUB — Returns a placeholder token response.

    Real implementation:
        1. Client signs in via Firebase Auth SDK and receives an ID token.
        2. Client sends the ID token as a Bearer header to protected endpoints.
        3. Backend verifies the token with firebase_admin.auth.verify_id_token().
    """
    return TokenResponse(
        uid="stub-uid-001",
        email=body.email,
        token="stub-firebase-id-token",
    )


@router.post("/register", status_code=201, summary="Register a new user")
async def register(body: LoginRequest):
    """
    STUB — Registration is handled client-side via Firebase Auth SDK.
    This endpoint exists as a placeholder for any server-side post-registration
    logic (e.g., creating a Firestore user profile document).
    """
    return {"message": "User registration stub — handled by Firebase Auth on client."}


@router.get("/me", response_model=UserProfileResponse, summary="Get current user profile")
async def get_me(authorization: str = Header(...)):
    """
    STUB — Returns a placeholder user profile.

    Real implementation:
        decoded = firebase_admin.auth.verify_id_token(token)
        uid = decoded["uid"]
        # fetch from Firestore users/{uid}
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header format.")
    return UserProfileResponse(uid="stub-uid-001", email="user@example.com")


@router.post("/logout", summary="Log out current user")
async def logout():
    """
    STUB — Logout is handled client-side by revoking the Firebase token.
    """
    return {"message": "Logout stub — revoke token client-side via Firebase Auth SDK."}
