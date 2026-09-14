from pydantic import BaseModel
from typing import List, Optional

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    session_id: Optional[str] = None
    user_id: Optional[str] = None
    message: str
    history: List[ChatMessage] = []

class WriterRequest(BaseModel):
    target_output: str # Essay, Email, Script, Social Caption, Translation
    topic: str
    tone: Optional[str] = "professional"
    language: Optional[str] = "English"
    length: Optional[str] = "medium"

class ResumeRequest(BaseModel):
    personal_info: dict
    education: list
    experience: list
    skills: list

class ImageRequest(BaseModel):
    image_base64: str
