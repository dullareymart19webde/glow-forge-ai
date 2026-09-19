from groq import Groq
from core.config import GROQ_API_KEY

def get_groq_client() -> Groq:
    return Groq(api_key=GROQ_API_KEY)

def generate_chat_response(messages: list, model: str = "openai/gpt-oss-120b"):
    client = get_groq_client()
    response = client.chat.completions.create(
        model=model,
        messages=messages
    )
    return response.choices[0].message.content

def generate_json_response(messages: list, model: str = "openai/gpt-oss-20b"):
    client = get_groq_client()
    response = client.chat.completions.create(
        model=model,
        messages=messages,
        response_format={"type": "json_object"}
    )
    return response.choices[0].message.content
