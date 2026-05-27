"""
routers/auth.py
---------------
Stub router for /auth endpoints.
Real implementation will verify Firebase ID tokens using firebase-admin.
"""

import os
import requests
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from firebase_admin import auth as firebase_auth
from core.security import verify_token

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
    Authenticates via Firebase Identity Toolkit (REST API).
    Requires FIREBASE_WEB_API_KEY in .env.
    """
    api_key = os.getenv("FIREBASE_API_KEY") or os.getenv("FIREBASE_WEB_API_KEY")
    if not api_key:
        # Fallback to stub if API key isn't provided
        return TokenResponse(
            uid="stub-uid-001",
            email=body.email,
            token="stub-firebase-id-token",
        )
    
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}"
    resp = requests.post(url, json={
        "email": body.email,
        "password": body.password,
        "returnSecureToken": True
    })
    
    if resp.status_code != 200:
        raise HTTPException(status_code=401, detail="Invalid credentials")
        
    data = resp.json()
    return TokenResponse(
        uid=data["localId"],
        email=data["email"],
        token=data["idToken"],
    )


@router.post("/signup", status_code=201, summary="Register a new user")
async def signup(body: LoginRequest):
    """
    Creates a new user in Firebase Auth.
    """
    try:
        user = firebase_auth.create_user(
            email=body.email,
            password=body.password
        )
        return {"uid": user.uid, "email": user.email, "message": "User registered successfully."}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/me", response_model=UserProfileResponse, summary="Get current user profile")
async def get_me(decoded_token: dict = Depends(verify_token)):
    """
    Returns the current user profile based on the verified token.
    """
    return UserProfileResponse(
        uid=decoded_token.get("uid"),
        email=decoded_token.get("email", "")
    )


@router.post("/logout", summary="Log out current user")
async def logout():
    """
    STUB — Logout is handled client-side by revoking the Firebase token.
    """
    return {"message": "Logout stub — revoke token client-side via Firebase Auth SDK."}
