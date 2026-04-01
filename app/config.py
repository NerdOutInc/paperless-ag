import os
from urllib.parse import quote

PAPERLESS_API_URL = os.getenv("PAPERLESS_API_URL", "http://localhost:8000")
PAPERLESS_USERNAME = os.getenv("PAPERLESS_USERNAME", "admin")
PAPERLESS_PASSWORD = os.getenv("PAPERLESS_PASSWORD", "admin")
def _build_database_url():
    url = os.getenv("DATABASE_URL")
    if url:
        return url
    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "5432")
    name = os.getenv("DB_NAME", "paperless")
    user = os.getenv("DB_USER", "paperless")
    password = os.getenv("DB_PASS", "paperless-dev")
    return f"postgresql://{quote(user, safe='')}:{quote(password, safe='')}@{host}:{port}/{name}"

DATABASE_URL = _build_database_url()
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
SYNC_INTERVAL = int(os.getenv("SYNC_INTERVAL_SECONDS", "60"))
CHUNK_SIZE = int(os.getenv("CHUNK_SIZE_TOKENS", "500"))
CHUNK_OVERLAP = int(os.getenv("CHUNK_OVERLAP_TOKENS", "50"))
MCP_PORT = int(os.getenv("MCP_HTTP_PORT", "3001"))
MCP_AUTH_TOKEN = os.getenv("MCP_AUTH_TOKEN", "")
