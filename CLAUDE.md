# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Paperless Ag is a companion Docker container for [Paperless NGX](https://github.com/paperless-ngx/paperless-ngx) that adds semantic search and an MCP server for Claude integration. It lets farmers search their document archive using natural language. Paperless NGX stays completely stock.

## Architecture

```plaintext
Paperless NGX (stock)  <-->  Companion Container  <-->  PostgreSQL + pgvector
     Web UI (:8000)          Embedding Worker              document_embeddings table
     REST API                MCP Server (:3001)            (shared with Paperless)
     Consumer                Search API
```

**Document flow:** Paperless ingests/OCRs docs -> Embedding Worker polls for new docs -> text chunked (500-word windows, 50-word overlap) -> embeddings generated locally (all-MiniLM-L6-v2, 384-d vectors) -> stored in pgvector -> searched via hybrid semantic+keyword with RRF scoring.

**Key design decisions:**

- Companion container pattern: never modify upstream Paperless NGX
- pgvector in the same Postgres instance Paperless already uses (no separate vector DB)
- Hybrid search combines pgvector cosine similarity with Paperless keyword API via Reciprocal Rank Fusion (k=60)
- Local embedding model (all-MiniLM-L6-v2) -- no external API calls
- 100% environment-based configuration (see `app/config.py`)

## Commands

### Full stack (Docker Compose)

```bash
docker compose up -d              # Start all services
docker compose logs -f app        # Watch companion container logs
docker compose down               # Stop (keep data)
docker compose down -v            # Stop and delete all data
```

Services: Paperless at :8000 (admin/admin), MCP server at :3001/sse. Postgres and Redis are internal to the Docker network (not published to host).

### Test data

```bash
cd test-data
pip3 install -r requirements.txt
python3 generate.py               # Generate 100 PDFs (skips existing; --force to overwrite)
python3 upload.py                 # Upload to Paperless with metadata (--dry-run to preview)
```

Requires Google Chrome for headless HTML-to-PDF conversion.

### Rebuild companion container

```bash
docker compose build app && docker compose up -d app
```

## Code Layout

All companion container code lives in `app/`:

| File | Purpose |
| ------ | --------- |
| `main.py` | Entry point: retries DB connection, starts worker thread, runs MCP server (SSE) |
| `config.py` | All env vars in one place (validates int env vars) |
| `auth.py` | Thread-safe Paperless API token management with automatic re-auth on 401 |
| `db.py` | pgvector operations: init schema, store/query embeddings |
| `embeddings.py` | Model loading, text chunking, embedding generation |
| `worker.py` | `EmbeddingWorker` daemon thread: polls Paperless API, embeds new docs |
| `search.py` | Semantic, keyword, and hybrid search; Paperless API helpers |
| `mcp_server.py` | FastMCP server with 7 tools exposed to Claude |

`test-data/` has the PDF generator (`generate.py`, `upload.py`) with document manifests in `data/` and Jinja2 templates in `templates/`.

## MCP Tools

The MCP server (`mcp_server.py`) exposes: `search_documents`, `get_document`, `list_tags`, `list_document_types`, `search_by_tag`, `search_by_date_range`, `get_embedding_status`. Configured in `.mcp.json` as SSE on port 3001.

## Linting

After modifying any `.md` file, run `npx markdownlint-cli2 <files>` and fix any warnings before finishing.

After modifying any `.html` file, run `npx prettier --write <files>` to auto-format before finishing.

## Test Data

Three fictional farms: Horob Family Farms (row crops, West Fargo ND), Nerd Out Ranch (cattle, Fargo ND), Pattison Acres (diversified, Minneapolis MN). 100 documents across 18 types, with 20 "hero" (styled) and 80 "standard" templates. Manifests split across `test-data/data/manifest_crop.py`, `test-data/data/manifest_livestock.py`, `test-data/data/manifest_general.py`.
