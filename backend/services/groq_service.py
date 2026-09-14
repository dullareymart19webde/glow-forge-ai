from groq import Groq
from core.config import GROQ_API_KEY

def get_groq_client() -> Groq:
    return Groq(api_key=GROQ_API_KEY)

def generate_chat_response(messages: list, model: str = "llama-3.3-70b-versatile"):
    client = get_groq_client()
    response = client.chat.completions.create(
        model=model,
        messages=messages
    )
    return response.choices[0].message.content

def generate_json_response(messages: list, model: str = "llama-3.3-70b-versatile"):
    client = get_groq_client()
    response = client.chat.completions.create(
        model=model,
        messages=messages,
        response_format={"type": "json_object"}
    )
    return response.choices[0].message.content
