from fastapi import APIRouter, HTTPException
from models.schemas import ChatRequest
from services.groq_service import generate_chat_response

router = APIRouter()

@router.post("/")
async def chat_endpoint(request: ChatRequest):
    try:
        # Build messages for Groq
        messages = [{"role": "system", "content": "You are GlowForge AI, a helpful, intelligent assistant. CRITICAL: Do NOT use any Markdown formatting, bolding, italics, asterisks, or code blocks. Return ONLY pure, unformatted plain text."}]
        for msg in request.history:
            messages.append({"role": msg.role, "content": msg.content})
        
        messages.append({"role": "user", "content": request.message})

        # Generate response
        ai_response = generate_chat_response(messages)

        return {"response": ai_response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
