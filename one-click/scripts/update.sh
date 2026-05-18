#!/usr/bin/env bash
set -euo pipefail
umask 077
cd /opt/paperless-ag

mkdir -p backups

if docker compose ps --status running db 2>/dev/null | grep -q db; then
    echo "Backing up database before update..."
    docker compose exec -T db pg_dump --clean -U paperless paperless \
        > "backups/pre-update-$(date +%Y%m%d-%H%M%S).sql"
    echo "[OK] Database backed up"
else
    echo "[!] Database not running -- skipping backup"
fi

if [[ -f Caddyfile ]] && ! grep -q '@search path' Caddyfile; then
    sed -i '/^[[:space:]]*handle {$/i\    @search path \/search \/search\/*\n    handle @search {\n        reverse_proxy companion:3001 {\n            header_up Host localhost:3001\n        }\n    }' Caddyfile
    echo "[OK] Caddyfile search route added"
fi

echo "Pulling latest images..."
docker compose pull

echo "Restarting services..."
docker compose up -d

echo ""
echo "[OK] Update complete. Check your Paperless UI to confirm."
