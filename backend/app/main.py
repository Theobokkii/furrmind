from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import health, predict, reframe

app = FastAPI(
    title="Furrmind API",
    description="CBT Journal Companion - Cognitive Distortion Detection & Reframing API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
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
