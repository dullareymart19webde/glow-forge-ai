from fastapi import APIRouter, HTTPException
from models.schemas import WriterRequest
from services.groq_service import generate_chat_response

router = APIRouter()

@router.post("/")
async def writer_endpoint(request: WriterRequest):
    try:
        system_prompt = (
            f"You are a professional AI writer and translator. "
            f"Generate a {request.target_output} about the following topic. "
            f"Tone: {request.tone}. Language: {request.language}. Length: {request.length}."
        )

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": request.topic}
        ]

        response = generate_chat_response(messages)
        
        return {"result": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
