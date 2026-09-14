from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api import chat, writer, resume, image

app = FastAPI(title="GlowForge AI API", description="Backend for GlowForge AI Capstone Project")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # For development. In production, specify domains.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(chat.router, prefix="/api/chat", tags=["Chat"])
app.include_router(writer.router, prefix="/api/writer", tags=["Writer"])
app.include_router(resume.router, prefix="/api/resume", tags=["Resume"])
app.include_router(image.router, prefix="/api/image", tags=["Image"])

@app.get("/")
def read_root():
    return {"message": "Welcome to GlowForge AI API"}
