#!/usr/bin/env bash
set -euo pipefail
cd /opt/paperless-ag

echo "Starting Paperless Ag stack..."

# Stop the host Caddy so port 80 is free for the Docker Caddy
systemctl stop paperless-setup.service paperless-setup-api.service

docker compose up -d

echo "Waiting for Paperless to become healthy..."
timeout=300
elapsed=0
while [[ $elapsed -lt $timeout ]]; do
    if docker compose ps paperless 2>/dev/null | grep -q "(healthy)"; then
        echo "[OK] Paperless is healthy"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
done

if [[ $elapsed -ge $timeout ]]; then
    echo "[!] Paperless did not become healthy within ${timeout}s"
    exit 1
fi

# Disable the setup service so it never runs again
systemctl disable paperless-setup.service paperless-setup-api.service

# Register daily backup cron at 7 AM
(crontab -l 2>/dev/null || true; echo "0 7 * * * /opt/paperless-ag/scripts/backup.sh >> /opt/paperless-ag/backups/cron.log 2>&1") | crontab -

echo "[OK] Setup complete"
