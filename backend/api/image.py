from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from services.image_service import remove_background, auto_enhance, sharpen, sketch, black_white
from models.schemas import ImageRequest
import base64

router = APIRouter()

@router.post("/remove-bg")
async def remove_bg_endpoint(request: ImageRequest):
    try:
        contents = base64.b64decode(request.image_base64)
        output_bytes = remove_background(contents)
        output_b64 = base64.b64encode(output_bytes).decode('utf-8')
        return {"image_base64": output_b64}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/enhance")
async def enhance_endpoint(request: ImageRequest):
    try:
        contents = base64.b64decode(request.image_base64)
        output_bytes = auto_enhance(contents)
        output_b64 = base64.b64encode(output_bytes).decode('utf-8')
        return {"image_base64": output_b64}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/sharpen")
async def sharpen_endpoint(request: ImageRequest):
    try:
        contents = base64.b64decode(request.image_base64)
        output_bytes = sharpen(contents)
        output_b64 = base64.b64encode(output_bytes).decode('utf-8')
        return {"image_base64": output_b64}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/sketch")
async def sketch_endpoint(request: ImageRequest):
    try:
        contents = base64.b64decode(request.image_base64)
        output_bytes = sketch(contents)
        output_b64 = base64.b64encode(output_bytes).decode('utf-8')
        return {"image_base64": output_b64}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/black-white")
async def black_white_endpoint(request: ImageRequest):
    try:
        contents = base64.b64decode(request.image_base64)
        output_bytes = black_white(contents)
        output_b64 = base64.b64encode(output_bytes).decode('utf-8')
        return {"image_base64": output_b64}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



