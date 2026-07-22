# app/models/user.py
# Pydantic models for auth request/response validation.

from typing import Literal

from pydantic import BaseModel, EmailStr

# "admin" is deliberately excluded — it's not a self-signup choice.
# Admin promotion is an admin-only action via PATCH /users/{user_id}.
SelfSelectableRole = Literal["employee", "manager"]


class SignupRequest(BaseModel):
    email: EmailStr
    password: str
    display_name: str
    role: SelfSelectableRole = "employee"


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class AuthResponse(BaseModel):
    uid: str
    email: str
    display_name: str | None
    token: str  # Firebase ID token — sent with every protected request


class UserProfileResponse(BaseModel):
    uid: str
    email: str
    display_name: str | None = None
    role: str = "employee"
    is_active: bool = True


class UserProfileDetail(BaseModel):
    uid: str
    email: str
    display_name: str | None = None
    first_name: str | None = None
    last_name: str | None = None
    phone_number: str | None = None
    profile_image_url: str | None = None
    role: str = "employee"
    is_active: bool = True
    created_at: str | None = None
    updated_at: str | None = None


class UserProfileUpdateRequest(BaseModel):
    display_name: str | None = None
    first_name: str | None = None
    last_name: str | None = None
    phone_number: str | None = None


class UserAdminUpdateRequest(UserProfileUpdateRequest):
    # Only an admin-scoped request may change role/is_active — kept as a
    # separate model so the self-service update endpoint can never accept
    # these fields, even if a client sends them.
    role: str | None = None
    is_active: bool | None = None


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


class CompleteSignupRequest(BaseModel):
    # Called once, right after Firebase client-side signup, to create the
    # Firestore profile with the role the user picked. A no-op if the
    # profile already exists — role can't be changed through this route.
    role: SelfSelectableRole = "employee"
