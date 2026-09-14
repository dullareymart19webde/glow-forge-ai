from supabase import create_client, Client
from .config import SUPABASE_URL, SUPABASE_KEY

def get_supabase() -> Client:
    if not SUPABASE_URL or not SUPABASE_KEY:
        # Returning a dummy client or raising an error depending on your preference.
        # For scaffolding, we might just pass empty strings to avoid immediate crash
        # but operations will fail.
        print("Warning: SUPABASE_URL or SUPABASE_KEY is missing.")
    return create_client(SUPABASE_URL or "http://localhost", SUPABASE_KEY or "dummy_key")
