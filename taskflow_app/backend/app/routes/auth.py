# app/routes/auth.py
# Auth routes — signup and login.
# Delegates all logic to app.services.auth_service.

from fastapi import APIRouter, HTTPException
from app.models.user import SignupRequest, LoginRequest, AuthResponse
from app.services import auth_service

router = APIRouter()


@router.post("/signup", response_model=AuthResponse)
async def signup(request: SignupRequest):
    # Create a new user in Firebase Auth and return a token
    return await auth_service.signup(request)


@router.post("/login", response_model=AuthResponse)
async def login(request: LoginRequest):
    # Verify credentials via Firebase and return a token
    return await auth_service.login(request)