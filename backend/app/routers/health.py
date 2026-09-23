from fastapi import APIRouter
from app.services import onnx_service
from app.models.schemas import HealthResponse

router = APIRouter()


@router.get("/health", response_model=HealthResponse, tags=["Health"])
def health_check():
    return HealthResponse(
        status="ok",
        model_loaded=onnx_service.is_model_loaded()
    )
