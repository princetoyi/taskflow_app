"""
routers/auth.py
---------------
Authentication endpoints with Firestore integration for user profiles.
"""

import os
import requests
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, EmailStr
from firebase_admin import auth as firebase_auth
from core.security import verify_token
from app.repositories import UserRepository
from app.models.user import SignupRequest, AuthResponse

router = APIRouter(prefix="/auth", tags=["auth"])


# ── Schemas ───────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserProfileResponse(BaseModel):
    uid: str
    email: str
    display_name: str | None = None
    role: str | None = None


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/login", response_model=AuthResponse, summary="Log in with email & password")
async def login(body: LoginRequest):
    """
    Authenticates via Firebase Identity Toolkit (REST API).
    Requires FIREBASE_API_KEY in .env.
    """
    api_key = os.getenv("FIREBASE_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="Firebase API key not configured")
    
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}"
    
    try:
        resp = requests.post(url, json={
            "email": str(body.email),
            "password": body.password,
            "returnSecureToken": True
        }, timeout=10)
        
        if resp.status_code != 200:
            error_data = resp.json()
            detail = error_data.get("error", {}).get("message", "Invalid credentials")
            raise HTTPException(status_code=401, detail=detail)
        
        data = resp.json()
        uid = data["localId"]
        
        # Ensure user profile exists in Firestore
        user = UserRepository.get_user(uid)
        if not user:
            UserRepository.create_user(
                uid=uid,
                email=str(body.email),
                display_name=data.get("displayName"),
                role="employee"  # Default role
            )
        
        return AuthResponse(
            uid=uid,
            email=data.get("email", ""),
            display_name=data.get("displayName"),
            token=data["idToken"],
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Login failed: {str(e)}")


@router.post("/signup", status_code=201, response_model=AuthResponse, summary="Register a new user")
async def signup(body: SignupRequest):
    """
    Creates a new user in Firebase Auth and saves profile to Firestore.
    """
    try:
        # Create user in Firebase Auth
        user = firebase_auth.create_user(
            email=str(body.email),
            password=body.password,
            display_name=body.display_name
        )
        
        # Create user profile in Firestore
        UserRepository.create_user(
            uid=user.uid,
            email=str(body.email),
            display_name=body.display_name,
            role="employee"  # Default role
        )
        
        # Return auth response
        return AuthResponse(
            uid=user.uid,
            email=user.email,
            display_name=user.display_name,
            token=""  # Client needs to get token via Firebase SDK
        )
    except firebase_auth.EmailAlreadyExistsError:
        raise HTTPException(status_code=400, detail="Email already registered")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Signup failed: {str(e)}")


@router.get("/me", response_model=UserProfileResponse, summary="Get current user profile")
async def get_me(decoded_token: dict = Depends(verify_token)):
    """
    Returns the current user profile from Firestore.
    """
    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    try:
        user = UserRepository.get_user(uid)
        
        if not user:
            # Create profile if doesn't exist
            email = decoded_token.get("email", "")
            display_name = decoded_token.get("name")
            user = UserRepository.create_user(
                uid=uid,
                email=email,
                display_name=display_name,
                role="employee"
            )
        
        return UserProfileResponse(
            uid=uid,
            email=user.get("email", ""),
            display_name=user.get("display_name"),
            role=user.get("role")
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/logout", summary="Log out current user")
async def logout():
    """
    Logout is handled client-side by revoking the Firebase token.
    This endpoint is here for completeness but doesn't require backend action.
    """
    return {"message": "Logout successful. Please revoke token client-side."}
