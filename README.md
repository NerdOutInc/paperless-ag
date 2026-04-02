# Paperless Ag

A companion container for [Paperless NGX](https://github.com/paperless-ngx/paperless-ngx) that adds semantic search and an MCP server for Claude integration. Built for the [Fullstack Ag](https://fullstack.ag) community.

## Deploy

SSH into any Linux server and run:

```bash
curl -fsSL https://paperless.fullstack.ag/install.sh | bash
```

The installer detects if you already have Paperless NGX running and walks you through setup. Works on any VPS -- pick one to get started:

[![Deploy on DigitalOcean](https://img.shields.io/badge/Deploy-DigitalOcean-0080FF?style=for-the-badge&logo=digitalocean)](https://cloud.digitalocean.com/droplets/new?size=s-2vcpu-4gb&image=docker-20-04&region=nyc1)
[![Deploy on Hetzner](https://img.shields.io/badge/Deploy-Hetzner-D50C2D?style=for-the-badge&logo=hetzner)](https://console.hetzner.cloud/)
[![Deploy on Vultr](https://img.shields.io/badge/Deploy-Vultr-007BFC?style=for-the-badge&logo=vultr)](https://www.vultr.com/products/cloud-compute/)

> **Recommended specs:** 2 vCPU, 4+ GB RAM (~$10-24/mo depending on provider). New DigitalOcean accounts get $200 in free credits.

## The Problem

Farmers and ranchers accumulate a lot of documents -- leases, seed contracts, crop insurance policies, FSA paperwork, chemical application records, equipment manuals, tax returns, succession plans, soil test results. Most of this ends up in filing cabinets, scattered Google Drive folders, or boxes in the shop.

The problem is retrieval. Paperless NGX handles ingestion, OCR, and keyword search well, but keyword search only works when you remember the exact words in the document. Search "fertilizer recommendations" when the document says "nutrient management plan" and you get zero results.

## What This Adds

A single Docker container that sits alongside a stock Paperless NGX installation and provides:

1. **Semantic search via pgvector** -- extends the Postgres database Paperless already requires. No additional vector database needed.
2. **An MCP server for Claude** -- lets farmers search their entire document archive through conversation in Claude Desktop or Claude Code.

Paperless NGX stays completely stock. Free upstream updates forever.

## Architecture

```plaintext
Paperless NGX (stock)  <-->  Companion Container  <-->  PostgreSQL + pgvector
     Web UI (:8000)          Embedding Worker              document_embeddings table
     REST API                MCP Server (:3001)            (shared with Paperless)
     Consumer                Search API
```

The companion container:

- Polls Paperless for new documents and generates vector embeddings using a local model (all-MiniLM-L6-v2)
- Stores chunk-level embeddings in pgvector alongside Paperless's existing tables
- Exposes hybrid search (semantic + keyword) through an MCP server that Claude can call directly

## Local Development

### Prerequisites

- Docker and Docker Compose
- Python 3.11+
- Google Chrome (for test data PDF generation)

### Start Paperless NGX and companion app

```bash
docker compose up -d
```

Paperless will be available at <http://localhost:8000> (admin / admin).

### Load Test Data

The `test-data/` directory contains a generator that creates 100 fake farm/ranch PDFs and uploads them to Paperless with metadata for testing in development:

```bash
cd test-data
pip3 install -r requirements.txt
python3 generate.py    # Generate 100 PDFs
python3 upload.py      # Upload to Paperless with metadata
```

See [test-data/README.md](test-data/README.md) for details on the test documents, farms, and document types.

## Connect to Claude

After installation, connect your MCP server to Claude so you can search documents through conversation.

### Claude Code

```bash
claude mcp add --transport sse paperless-ag https://YOUR_DOMAIN/mcp/sse \
  --header "Authorization: Bearer YOUR_MCP_TOKEN"
```

### Claude Desktop / .mcp.json

Add this to your Claude Desktop config or `.mcp.json`:

```json
{
  "mcpServers": {
    "paperless-ag": {
      "type": "sse",
      "url": "https://YOUR_DOMAIN/mcp/sse",
      "headers": {
        "Authorization": "Bearer YOUR_MCP_TOKEN"
      }
    }
  }
}
```

Replace `YOUR_DOMAIN` with your server's domain or IP, and `YOUR_MCP_TOKEN` with the token shown at the end of the install script. If you've lost the token, check your `.env` file:

```bash
grep MCP_AUTH_TOKEN /root/paperless-ag/.env
```

Then try asking Claude: *"Search my farm documents for crop insurance"*

## Project Status

This project is in early development. Current progress:

- [x] Local Paperless NGX dev stack (Docker Compose with pgvector-enabled Postgres)
- [x] Test data generator (100 realistic farm documents across 3 fictional farms)
- [x] Companion container with embedding worker
- [x] pgvector search API (semantic + hybrid)
- [x] MCP server for Claude integration
- [x] Install script for VPS deployment
- [ ] DigitalOcean 1-click Marketplace image
