# Paperless Ag

A companion container for [Paperless NGX](https://github.com/paperless-ngx/paperless-ngx) that adds semantic search and an MCP server for Claude integration. Built for the [Fullstack Ag](https://fullstack.ag) community.

## The Problem

Farmers and ranchers accumulate a lot of documents -- leases, seed contracts, crop insurance policies, FSA paperwork, chemical application records, equipment manuals, tax returns, succession plans, soil test results. Most of this ends up in filing cabinets, scattered Google Drive folders, or boxes in the shop.

The problem is retrieval. Paperless NGX handles ingestion, OCR, and keyword search well, but keyword search only works when you remember the exact words in the document. Search "fertilizer recommendations" when the document says "nutrient management plan" and you get zero results.

## What This Adds

A single Docker container that sits alongside a stock Paperless NGX installation and provides:

1. **Semantic search via pgvector** -- extends the Postgres database Paperless already requires. No additional vector database needed.
2. **An MCP server for Claude** -- lets farmers search their entire document archive through conversation in Claude Desktop or Claude Code.

Paperless NGX stays completely stock.

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

## Connect to Claude

After installation, connect your MCP server to Claude so you can search documents through conversation.

The install script prints the exact commands with your server's URL and token. The general format is:

### Claude Code

```bash
claude mcp add --transport http paperless-ag YOUR_SERVER_URL/mcp \
  --header "Authorization: Bearer YOUR_MCP_TOKEN"
```

### VS Code / Cursor (`.mcp.json`)

Add this to your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "paperless-ag": {
      "type": "http",
      "url": "YOUR_SERVER_URL/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_MCP_TOKEN"
      }
    }
  }
}
```

### Claude Desktop (`claude_desktop_config.json`)

Claude Desktop doesn't support remote HTTP servers directly. Use `mcp-remote` as a bridge. Edit your config at `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "paperless-ag": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "YOUR_SERVER_URL/mcp",
        "--allow-http",
        "--header",
        "Authorization:Bearer YOUR_MCP_TOKEN"
      ],
      "env": {
        "PATH": "YOUR_NODE_BIN_DIR:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
      }
    }
  }
}
```

Replace `YOUR_NODE_BIN_DIR` with the directory containing your `node` binary. Claude Desktop doesn't inherit your shell's PATH, so it needs this to find `npx` and `node`. Find it by running:

```bash
dirname "$(which node)"
```

If you use `nvm` or `fnm`, use the real path instead of the ephemeral shell path:

```bash
dirname "$(readlink -f "$(which node)")"
```

If your server uses HTTPS, you can drop the `--allow-http` flag. The `env` block may not be needed if `node` is in a standard location like `/usr/local/bin`.

Replace `YOUR_SERVER_URL` with the URL from the install output (`https://yourdomain.com` if you configured a domain, or `http://YOUR_IP` if not) and `YOUR_MCP_TOKEN` with the token shown at the end of the install script. If you've lost the token, check your `.env` file (adjust the path if you chose a different install directory):

```bash
grep MCP_AUTH_TOKEN /root/paperless-ag/.env
```

Then try asking Claude: *"Search my farm documents for crop insurance"*

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

## Uninstall

To completely remove Paperless Ag and all its data from your server (`/root/paperless-ag` is the default install directory -- adjust if you chose a different path during setup):

```bash
cd /root/paperless-ag
docker compose down -v
crontab -l | grep -v paperless-ag | crontab -
cd ~
rm -rf /root/paperless-ag
```

> **Warning:** This deletes all documents and database contents. Run `bash /root/paperless-ag/backup.sh` first if you want to keep your data.

## Project Status

This project is in early development. Current progress:

- [x] Local Paperless NGX dev stack (Docker Compose with pgvector-enabled Postgres)
- [x] Test data generator (100 realistic farm documents across 3 fictional farms)
- [x] Companion container with embedding worker
- [x] pgvector search API (semantic + hybrid)
- [x] MCP server for Claude integration
- [x] Install script for VPS deployment
- [ ] DigitalOcean 1-click Marketplace image
