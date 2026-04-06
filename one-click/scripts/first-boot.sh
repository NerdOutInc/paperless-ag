#!/usr/bin/env bash
set -euo pipefail

# Regenerate SSH host keys (cleared during snapshot build)
dpkg-reconfigure openssh-server
systemctl restart ssh

# Start the setup wizard services
systemctl start paperless-setup-api.service
systemctl start paperless-setup.service

echo "Paperless Ag setup wizard is ready on port 80"
