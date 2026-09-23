from pydantic import BaseModel
from typing import List


class PredictRequest(BaseModel):
    text: str


class DistortionResult(BaseModel):
    label: str
    confidence: float
    triggered: bool


class PredictResponse(BaseModel):
    distortions: List[DistortionResult]


class ReframeRequest(BaseModel):
    text: str
    detected_distortions: List[str]


class ReframeResponse(BaseModel):
    reframe: str
    explanation: str
    sources: List[str]


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
