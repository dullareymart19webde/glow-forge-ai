from fastapi import APIRouter, HTTPException
from models.schemas import WriterRequest
from services.groq_service import generate_chat_response

router = APIRouter()

@router.post("/generate/")
async def writer_endpoint(request: WriterRequest):
    try:
        system_prompt = (
            f"You are a professional AI writer and translator. "
            f"Generate a {request.target_output} about the following topic. "
            f"Tone: {request.tone}. Language: {request.language}. Length: {request.length}. "
            f"CRITICAL: Do NOT use any Markdown formatting, bolding, italics, asterisks, or code blocks. Return ONLY pure, unformatted plain text."
        )

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": request.topic}
        ]

        response = generate_chat_response(messages)
        
        return {"result": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
