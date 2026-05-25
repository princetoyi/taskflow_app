# app/main.py
# Entry point for the TaskFlow FastAPI backend.
# Registers all routers and initialises Firebase on startup.
# Following NexMotion Junior Developer Handbook v2.0.0

from fastapi import FastAPI
from contextlib import asynccontextmanager
from dotenv import load_dotenv
from app.routes import auth, tasks, users
from app.firebase_config import initialize_firebase
import logging

# Load .env before anything else — Firebase config depends on these values
load_dotenv()

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup — initialise Firebase Admin SDK once at boot,
    # not on every request, to avoid multiple app instances
    initialize_firebase()
    logger.info("Firebase initialised successfully")
    yield
    # Shutdown — nothing to clean up for Firebase Admin SDK
    logger.info("TaskFlow API shutting down")


app = FastAPI(
    title="TaskFlow API",
    description="Backend API for the TaskFlow task management application — NexMotion Technologies",
    version="1.0.0",
    lifespan=lifespan,
)

# Register route layers — thin routers that delegate to services
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(tasks.router, prefix="/tasks", tags=["Tasks"])
app.include_router(users.router, prefix="/users", tags=["Users"])

@app.get("/")
async def root() -> dict[str, str]:
    # Health check for deployment verification
    return {"message": "TaskFlow API is running"}


@app.get("/health")
async def health_check() -> dict[str, str]:
    # Used by CI/CD and Firebase hosting to confirm the server is alive
    return {"status": "healthy"}