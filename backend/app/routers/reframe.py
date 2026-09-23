from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from app.models.schemas import ReframeRequest, ReframeResponse
from app.services import gemini_service
from app.services.guardrail_service import check_guardrail

router = APIRouter()


@router.post("/reframe", response_model=ReframeResponse, tags=["Inference"])
def reframe(request: ReframeRequest):
    if not request.text or not request.text.strip():
        raise HTTPException(status_code=422, detail="Text cannot be empty.")

    if not request.detected_distortions:
        raise HTTPException(status_code=422, detail="detected_distortions cannot be empty.")

    guardrail_result = check_guardrail(request.text)
    is_distressed = guardrail_result["type"] == "distress"

    try:
        result = gemini_service.reframe(
            text=request.text,
            distortions=request.detected_distortions,
            is_distressed=is_distressed
        )
        return ReframeResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Reframe error: {str(e)}")


@router.post("/reframe/stream", tags=["Inference"])
async def reframe_stream(request: ReframeRequest):
    if not request.text or not request.text.strip():
        raise HTTPException(status_code=422, detail="Text cannot be empty.")

    guardrail_result = check_guardrail(request.text)
    is_distressed = guardrail_result["type"] == "distress"

    async def generator():
        async for chunk in gemini_service.reframe_stream(
            text=request.text,
            distortions=request.detected_distortions,
            is_distressed=is_distressed
        ):
            yield chunk

    return StreamingResponse(generator(), media_type="text/plain")
