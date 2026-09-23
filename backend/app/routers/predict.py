from fastapi import APIRouter, HTTPException
from app.models.schemas import PredictRequest, PredictResponse
from app.services import onnx_service
from app.services.guardrail_service import check_guardrail

router = APIRouter()


@router.post("/predict", response_model=PredictResponse, tags=["Inference"])
def predict(request: PredictRequest):
    if not request.text or not request.text.strip():
        raise HTTPException(status_code=422, detail="Text cannot be empty.")

    guardrail_result = check_guardrail(request.text)
    if guardrail_result["type"] == "crisis":
        raise HTTPException(
            status_code=200,
            detail={
                "guardrail": "crisis",
                "message": guardrail_result["message"],
                "resources": guardrail_result["resources"],
                "action": guardrail_result["action"]
            }
        )

    try:
        results = onnx_service.predict(request.text)
        return PredictResponse(distortions=results)
    except FileNotFoundError as e:
        raise HTTPException(status_code=503, detail=f"Model not available: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference error: {str(e)}")
