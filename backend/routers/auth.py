"""
routers/auth.py
---------------
Router for /auth endpoints.
Verifies Firebase ID tokens, manages user profiles in Firestore.
"""

import os
import requests
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from firebase_admin import auth as firebase_auth
from core.security import verify_token
from core.firebase import db

router = APIRouter(prefix="/auth", tags=["auth"])


# ── Schemas ───────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    email: str
    password: str


class SignupRequest(BaseModel):
    email: str
    password: str
    display_name: str | None = None
    role: str = "worker"  # "manager" or "worker"


class TokenResponse(BaseModel):
    uid: str
    email: str
    token: str
    display_name: str | None = None
    role: str = "worker"


class UserProfileResponse(BaseModel):
    uid: str
    email: str
    display_name: str | None = None
    role: str = "worker"


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/login", response_model=TokenResponse, summary="Log in with email & password")
async def login(body: LoginRequest):
    api_key = os.getenv("FIREBASE_API_KEY") or os.getenv("FIREBASE_WEB_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="Firebase API key not configured.")

    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}"
    resp = requests.post(url, json={
        "email": body.email,
        "password": body.password,
        "returnSecureToken": True
    })

    if resp.status_code != 200:
        raise HTTPException(status_code=401, detail="Invalid email or password.")

    data = resp.json()
    uid = data["localId"]

    # Fetch role from Firestore
    role = "worker"
    if db is not None:
        doc = db.collection("users").document(uid).get()
        if doc.exists:
            role = doc.to_dict().get("role", "worker")

    return TokenResponse(
        uid=uid,
        email=data["email"],
        token=data["idToken"],
        display_name=data.get("displayName"),
        role=role,
    )


@router.post("/signup", response_model=TokenResponse, status_code=201, summary="Register a new user")
async def signup(body: SignupRequest):
    try:
        create_kwargs = {"email": body.email, "password": body.password}
        if body.display_name:
            create_kwargs["display_name"] = body.display_name

        user = firebase_auth.create_user(**create_kwargs)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    # Save role and display_name to Firestore
    if db is not None:
        db.collection("users").document(user.uid).set({
            "email": body.email,
            "display_name": body.display_name,
            "role": body.role,
            "theme": "light",
        })

    # Get ID token via REST API
    token = None
    api_key = os.getenv("FIREBASE_API_KEY") or os.getenv("FIREBASE_WEB_API_KEY")
    if api_key:
        try:
            url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}"
            resp = requests.post(url, json={
                "email": body.email,
                "password": body.password,
                "returnSecureToken": True
            })
            if resp.status_code == 200:
                token = resp.json()["idToken"]
        except Exception:
            pass

    if not token:
        try:
            token = firebase_auth.create_custom_token(user.uid).decode("utf-8")
        except Exception:
            token = ""

    return TokenResponse(
        uid=user.uid,
        email=user.email,
        token=token,
        display_name=body.display_name,
        role=body.role,
    )


@router.get("/me", response_model=UserProfileResponse, summary="Get current user profile")
async def get_me(decoded_token: dict = Depends(verify_token)):
    uid = decoded_token.get("uid")
    email = decoded_token.get("email", "")
    display_name = decoded_token.get("name")

    # Fetch role from Firestore — do NOT expose raw uid in response beyond what's needed
    role = "worker"
    if db is not None:
        doc = db.collection("users").document(uid).get()
        if doc.exists:
            data = doc.to_dict()
            role = data.get("role", "worker")
            display_name = display_name or data.get("display_name")

    return UserProfileResponse(
        uid=uid,
        email=email,
        display_name=display_name,
        role=role,
    )


@router.post("/logout", summary="Log out current user")
async def logout():
    return {"message": "Logout handled client-side — revoke Firebase token via Auth SDK."}