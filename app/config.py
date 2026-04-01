import os

PAPERLESS_API_URL = os.getenv("PAPERLESS_API_URL", "http://localhost:8000")
PAPERLESS_USERNAME = os.getenv("PAPERLESS_USERNAME", "admin")
PAPERLESS_PASSWORD = os.getenv("PAPERLESS_PASSWORD", "admin")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://paperless:paperless-dev@localhost:5432/paperless")
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
SYNC_INTERVAL = int(os.getenv("SYNC_INTERVAL_SECONDS", "60"))
CHUNK_SIZE = int(os.getenv("CHUNK_SIZE_TOKENS", "500"))
CHUNK_OVERLAP = int(os.getenv("CHUNK_OVERLAP_TOKENS", "50"))
MCP_PORT = int(os.getenv("MCP_HTTP_PORT", "3001"))
