from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import health, predict, reframe, auth
from app.services.firebase_service import init_firebase


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize Firebase Admin SDK on app startup."""
    init_firebase()
    yield


app = FastAPI(
    title="Furrmind API",
    description="CBT Journal Companion - Cognitive Distortion Detection & Reframing API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

app.include_router(health.router)
app.include_router(predict.router)
app.include_router(reframe.router)
app.include_router(auth.router)
