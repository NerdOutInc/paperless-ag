import os
import threading
import time
import config
import db
from worker import EmbeddingWorker
from mcp_server import mcp


def main():
    print("=" * 50)
    print("Paperless Ag Companion Container")
    print("=" * 50)

    # Initialize database (retry in case DB isn't ready yet)
    for attempt in range(15):
        try:
            db.init_db()
            print("Database schema ready.")
            break
        except Exception as e:
            print(f"Waiting for database... (attempt {attempt + 1}): {e}")
            time.sleep(5)
    else:
        print("ERROR: Could not connect to database after 15 attempts")
        return

    # Start embedding worker in background thread
    worker = EmbeddingWorker()
    worker_thread = threading.Thread(target=worker.run, daemon=True, name="embedding-worker")
    worker_thread.start()
    print(f"Embedding worker started (sync every {config.SYNC_INTERVAL}s)")

    # Configure MCP server port and host
    mcp.settings.port = config.MCP_PORT
    mcp.settings.host = "0.0.0.0"

    # Start MCP server (blocks)
    print(f"Starting MCP server (SSE) on port {config.MCP_PORT}...")
    mcp.run(transport="sse")


if __name__ == "__main__":
    main()
