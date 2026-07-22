# app/routes/auth.py
# Auth routes — signup and login.
# Delegates all logic to app.services.auth_service.

from fastapi import APIRouter, Depends
from app.models.user import (
    SignupRequest,
    LoginRequest,
    AuthResponse,
    UserProfileResponse,
    CompleteSignupRequest,
)
from app.services import auth_service
from app.middleware.auth_middleware import get_current_user

router = APIRouter()


@router.post("/signup", response_model=AuthResponse)
async def signup(request: SignupRequest):
    # Create a new user in Firebase Auth and return a token
    return await auth_service.signup(request)


@router.post("/login", response_model=AuthResponse)
async def login(request: LoginRequest):
    # Verify credentials via Firebase and return a token
    return await auth_service.login(request)


@router.get("/me", response_model=UserProfileResponse)
async def me(user: dict = Depends(get_current_user)):
    # Returns the caller's Firestore profile (role, active status, etc.),
    # self-healing it into existence if it's missing.
    return await auth_service.get_current_user_profile(
        uid=user["uid"],
        email=user.get("email", ""),
        display_name=user.get("name"),
    )


@router.post("/logout")
async def logout(user: dict = Depends(get_current_user)):
    return await auth_service.logout()


@router.post("/complete-signup", response_model=UserProfileResponse)
async def complete_signup(body: CompleteSignupRequest, user: dict = Depends(get_current_user)):
    # Called once, right after Firebase client-side signup, to create the
    # Firestore profile with the role the user picked on the signup screen.
    # The actual signup flow is client-side (Firebase Auth SDK), not
    # POST /auth/signup — this is the real profile-creation moment.
    return await auth_service.get_current_user_profile(
        uid=user["uid"],
        email=user.get("email", ""),
        display_name=user.get("name"),
        role=body.role,
    )