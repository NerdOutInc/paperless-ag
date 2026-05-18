#!/usr/bin/env bash
set -euo pipefail
cd /opt/paperless-ag

echo "Starting Paperless Ag stack..."

# Stop only the host Caddy so port 80 is free for the Docker Caddy.
# Do NOT stop paperless-setup-api.service here -- this script runs as a
# child of that service, so stopping it would kill this process mid-setup.
systemctl stop paperless-setup.service

if ! docker compose up -d; then
    echo "[!] Docker Compose failed to start"
    echo "failed" > /opt/paperless-ag/.setup-state
    exit 1
fi

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
    echo "failed" > /opt/paperless-ag/.setup-state
    exit 1
fi

echo "Waiting for local AI models to finish downloading..."
timeout=3600
elapsed=0
while [[ $elapsed -lt $timeout ]]; do
    container_id="$(docker compose ps -q llama-model-init 2>/dev/null || true)"
    if [[ -n "$container_id" ]]; then
        status="$(docker inspect -f '{{.State.Status}}' "$container_id" 2>/dev/null || true)"
        exit_code="$(docker inspect -f '{{.State.ExitCode}}' "$container_id" 2>/dev/null || true)"
        if [[ "$status" == "exited" && "$exit_code" == "0" ]]; then
            echo "[OK] Local AI models downloaded"
            break
        fi
        if [[ "$status" == "exited" ]]; then
            echo "[!] Local AI model download failed"
            echo "failed" > /opt/paperless-ag/.setup-state
            exit 1
        fi
    fi
    sleep 10
    elapsed=$((elapsed + 10))
done

if [[ $elapsed -ge $timeout ]]; then
    echo "[!] Local AI model download did not finish within ${timeout}s"
    echo "failed" > /opt/paperless-ag/.setup-state
    exit 1
fi

echo "Waiting for llama.cpp Web UI to start..."
timeout=180
elapsed=0
while [[ $elapsed -lt $timeout ]]; do
    if docker compose ps llama 2>/dev/null | grep -q "running"; then
        echo "[OK] llama.cpp Web UI is running"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
done

if [[ $elapsed -ge $timeout ]]; then
    echo "[!] llama.cpp Web UI did not start within ${timeout}s"
    echo "failed" > /opt/paperless-ag/.setup-state
    exit 1
fi

# Write state before stopping the API -- the Python daemon thread is killed
# by SIGTERM before it can write this itself (KillMode=process).
echo "complete" > /opt/paperless-ag/.setup-state

# Now that the stack is up, disable and stop both setup services
systemctl disable --now paperless-setup.service paperless-setup-api.service

# Remove setup-only artifacts so the bootstrap token is no longer exposed
rm -f /etc/update-motd.d/99-paperless-setup
if command -v shred >/dev/null 2>&1; then
    shred -u /opt/paperless-ag/.setup-token 2>/dev/null || true
else
    rm -f /opt/paperless-ag/.setup-token
fi

# Register daily backup cron at 7 AM (idempotent)
cron_line="0 7 * * * /opt/paperless-ag/scripts/backup.sh >> /opt/paperless-ag/backups/cron.log 2>&1"
if command -v crontab >/dev/null 2>&1; then
    existing_crontab="$(crontab -l 2>/dev/null || true)"
    if ! printf '%s\n' "$existing_crontab" | grep -Fqx "$cron_line"; then
        printf '%s\n%s\n' "$existing_crontab" "$cron_line" | crontab -
    fi
else
    echo "[WARN] crontab not found; skipping daily backup cron"
fi

echo "[OK] Setup complete"
