# app/models/user.py
# Pydantic models for auth request/response validation.

from pydantic import BaseModel, EmailStr


class SignupRequest(BaseModel):
    email: EmailStr
    password: str
    display_name: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class AuthResponse(BaseModel):
    uid: str
    email: str
    display_name: str | None
    token: str  # Firebase ID token — sent with every protected request
