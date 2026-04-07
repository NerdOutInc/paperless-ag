#!/usr/bin/env bash
set -euo pipefail

echo "=== Paperless Ag Image Provisioning ==="

# 1. System updates
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# 2. Install Docker CE + Docker Compose v2
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# 3. Install Caddy (host-level, for setup wizard)
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
    | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
    > /etc/apt/sources.list.d/caddy-stable.list
apt-get update
apt-get install -y caddy

# Disable the default Caddy service (we use our own systemd unit)
systemctl disable caddy
systemctl stop caddy

# 4. Verify Python 3
python3 --version

# 5. Pre-pull all Docker images
mkdir -p /tmp/pull
cp /tmp/docker-compose.pull.yml /tmp/pull/docker-compose.yml
cd /tmp/pull
docker compose pull
cd /
rm -rf /tmp/pull

# 6. Copy application files into place
mkdir -p /opt/paperless-ag/{setup,templates,scripts,systemd,backups}
cp -r /tmp/one-click/setup/* /opt/paperless-ag/setup/
cp -r /tmp/one-click/templates/* /opt/paperless-ag/templates/
cp -r /tmp/one-click/scripts/* /opt/paperless-ag/scripts/
chmod +x /opt/paperless-ag/scripts/*.sh
chmod +x /opt/paperless-ag/setup/setup-api.py

# 7. Install systemd services
cp /tmp/one-click/systemd/paperless-setup.service /etc/systemd/system/
cp /tmp/one-click/systemd/paperless-setup-api.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable paperless-setup.service
systemctl enable paperless-setup-api.service

# 8. Install cloud-init config
mkdir -p /var/lib/cloud/scripts/per-instance
cp /opt/paperless-ag/scripts/first-boot.sh \
    /var/lib/cloud/scripts/per-instance/01-paperless-ag.sh
chmod +x /var/lib/cloud/scripts/per-instance/01-paperless-ag.sh

# 9. Snapshot hygiene
apt-get clean
rm -rf /var/lib/apt/lists/*
find /var/log -type f -name '*.log' -exec truncate -s 0 {} + 2>/dev/null || true
rm -f /etc/ssh/ssh_host_*
rm -f /root/.bash_history
cloud-init clean --logs

echo "=== Provisioning complete ==="
