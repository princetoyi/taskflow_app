"""
main.py
-------
FastAPI application entry point for the TaskFlow backend.

Run locally:
    uvicorn main:app --reload --port 8000

API docs (auto-generated):
    http://localhost:8000/docs    → Swagger UI
    http://localhost:8000/redoc  → ReDoc
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core import firebase
from routers import auth, tasks, users

# ── App instance ──────────────────────────────────────────────────────────────

app = FastAPI(
    title="TaskFlow API",
    description=(
        "Backend API for the TaskFlow task-management app. "
        "Authentication is handled by Firebase Auth on the client; "
        "this backend verifies Firebase ID tokens and manages Firestore data."
    ),
    version="0.1.0",
)

# ── CORS middleware (Day 5) ───────────────────────────────────────────────────
# Allows the Flutter web app (and local dev servers) to call this API.
# Update ALLOWED_ORIGINS before deploying to production.

ALLOWED_ORIGINS = [
    "http://localhost",
    "http://localhost:3000",   # Flutter web (default dev port)
    "http://localhost:5000",   # Alternative Flutter web port
    "http://localhost:8080",   # Alternative
    # Add your production Flutter web origin here, e.g.:
    # "https://taskflow.example.com",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],       # GET, POST, PATCH, DELETE, OPTIONS
    allow_headers=["*"],       # Authorization, Content-Type, etc.
)

# ── Routers ───────────────────────────────────────────────────────────────────

app.include_router(auth.router)
app.include_router(tasks.router)
app.include_router(users.router)

# ── Health check ──────────────────────────────────────────────────────────────

@app.get("/", tags=["health"])
async def root():
    return {"status": "ok", "service": "TaskFlow API", "version": "0.1.0"}


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok"}
