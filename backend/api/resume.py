import json
from fastapi import APIRouter, HTTPException
from models.schemas import ResumeRequest
from services.groq_service import generate_json_response

router = APIRouter()

@router.post("/generate/")
async def resume_endpoint(request: ResumeRequest):
    try:
        system_prompt = (
            "You are an expert ATS-friendly Resume Builder. "
            "You must output ONLY valid JSON representing a structured resume based on the user's input. "
            "Ensure the output matches this structure: "
            '{"personal_info": {}, "education": [], "experience": [], "skills": [], "summary": "A professional summary generated from the data"}'
        )

        user_content = json.dumps({
            "personal_info": request.personal_info,
            "education": request.education,
            "experience": request.experience,
            "skills": request.skills
        })

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_content}
        ]

        response = generate_json_response(messages)
        
        return json.loads(response)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
