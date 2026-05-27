# app/services/auth_service.py
# Handles Firebase Auth operations — signup and login.
# Login uses the Firebase REST API since the Admin SDK is server-side only
# and does not expose a password-based sign-in method.

import os
import httpx
from firebase_admin import auth
from fastapi import HTTPException
from app.models.user import SignupRequest, LoginRequest, AuthResponse

# Firebase REST API endpoint for email/password sign-in.
# Requires your Firebase Web API key — add FIREBASE_WEB_API_KEY to .env
FIREBASE_SIGN_IN_URL = (
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
)


async def signup(request: SignupRequest) -> AuthResponse:
    try:
        # Create user in Firebase Auth
        user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=request.display_name,
        )
        # Generate a custom token so the client can sign in immediately
        token = auth.create_custom_token(user.uid).decode("utf-8")

        return AuthResponse(
            uid=user.uid,
            email=user.email,
            display_name=user.display_name,
            token=token,
        )
    except auth.EmailAlreadyExistsError:
        raise HTTPException(status_code=400, detail="Email already registered")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


async def login(request: LoginRequest) -> AuthResponse:
    api_key = os.environ.get("FIREBASE_WEB_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="FIREBASE_WEB_API_KEY not set in .env")

    # Call Firebase REST API to verify email/password and get an ID token
    async with httpx.AsyncClient() as client:
        response = await client.post(
            FIREBASE_SIGN_IN_URL,
            params={"key": api_key},
            json={
                "email": request.email,
                "password": request.password,
                "returnSecureToken": True,
            },
        )

    if response.status_code != 200:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    data = response.json()
    return AuthResponse(
        uid=data["localId"],
        email=data["email"],
        display_name=data.get("displayName"),
        token=data["idToken"],
    )