#!/usr/bin/env python3
"""Setup wizard API for Paperless Ag 1-click image.

Handles form submission, generates config files, and kicks off
Docker Compose via finalize-setup.sh. Runs on localhost:8080,
proxied by host Caddy.

No pip dependencies -- stdlib only.
"""

import json
import os
import secrets
import string
import subprocess
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

BASE_DIR = Path("/opt/paperless-ag")
TEMPLATES_DIR = BASE_DIR / "templates"
SETUP_STATE_FILE = BASE_DIR / ".setup-state"

# Valid IANA timezones are in /usr/share/zoneinfo -- we check against it
ZONEINFO = Path("/usr/share/zoneinfo")


def generate_secret(length=32):
    """Generate a random alphanumeric string (matches install.sh pattern)."""
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def valid_timezone(tz):
    """Check timezone exists in system zoneinfo."""
    if not tz or ".." in tz or tz.startswith("/"):
        return False
    return (ZONEINFO / tz).is_file()


def render_template(template_path, variables):
    """Replace {{KEY}} placeholders in a template file."""
    content = template_path.read_text()
    for key, value in variables.items():
        content = content.replace("{{" + key + "}}", value)
    return content


def get_state():
    """Read current setup state."""
    if SETUP_STATE_FILE.exists():
        return SETUP_STATE_FILE.read_text().strip()
    return "pending"


def set_state(state):
    """Write setup state."""
    SETUP_STATE_FILE.write_text(state)


class SetupHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        """Suppress default access logs."""
        pass

    def _send_json(self, status, data):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_GET(self):
        if self.path == "/api/status":
            self._send_json(200, {"state": get_state()})
        else:
            self._send_json(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/api/setup":
            self._send_json(404, {"error": "not found"})
            return

        if get_state() != "pending":
            self._send_json(409, {"error": "setup already started"})
            return

        # Read request body
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            self._send_json(400, {"error": "invalid JSON"})
            return

        # Validate required fields
        admin_user = data.get("admin_user", "").strip()
        admin_password = data.get("admin_password", "").strip()
        timezone = data.get("timezone", "").strip()
        domain = data.get("domain", "").strip()
        le_email = data.get("le_email", "").strip()

        errors = []
        if not admin_user:
            errors.append("admin_user is required")
        if not admin_password:
            errors.append("admin_password is required")
        if len(admin_password) < 8:
            errors.append("admin_password must be at least 8 characters")
        if not timezone or not valid_timezone(timezone):
            errors.append("valid timezone is required")
        if domain and not le_email:
            errors.append("le_email is required when domain is provided")

        if errors:
            self._send_json(400, {"errors": errors})
            return

        set_state("in_progress")

        # Generate secrets
        db_password = generate_secret(32)
        secret_key = generate_secret(50)
        mcp_token = generate_secret(32)

        # Determine Paperless URL
        if domain:
            paperless_url = f"https://{domain}"
        else:
            # Get the droplet's public IP
            try:
                ip = subprocess.check_output(
                    ["curl", "-s", "-4", "http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address"],
                    timeout=5,
                ).decode().strip()
            except Exception:
                ip = "localhost"
            paperless_url = f"http://{ip}"

        # Template variables
        variables = {
            "ADMIN_USER": admin_user,
            "ADMIN_PASSWORD": admin_password,
            "DB_PASSWORD": db_password,
            "SECRET_KEY": secret_key,
            "TIMEZONE": timezone,
            "PAPERLESS_URL": paperless_url,
            "MCP_AUTH_TOKEN": mcp_token,
            "DOMAIN": domain,
            "LE_EMAIL": le_email,
        }

        # Render config files
        env_content = render_template(
            TEMPLATES_DIR / "env.template", variables
        )
        compose_content = render_template(
            TEMPLATES_DIR / "docker-compose.yml.tpl", variables
        )

        if domain:
            caddy_content = render_template(
                TEMPLATES_DIR / "Caddyfile.domain.tpl", variables
            )
        else:
            caddy_content = render_template(
                TEMPLATES_DIR / "Caddyfile.ip.tpl", variables
            )

        # Write config files
        env_path = BASE_DIR / ".env"
        env_path.write_text(env_content)
        env_path.chmod(0o600)

        (BASE_DIR / "docker-compose.yml").write_text(compose_content)
        (BASE_DIR / "Caddyfile").write_text(caddy_content)

        # Run finalize in background so we can return the response
        # before the host Caddy shuts down
        def finalize():
            subprocess.run(
                ["/opt/paperless-ag/scripts/finalize-setup.sh"],
                capture_output=True,
            )
            set_state("complete")

        threading.Thread(target=finalize, daemon=True).start()

        self._send_json(200, {
            "status": "started",
            "mcp_token": mcp_token,
            "paperless_url": paperless_url,
        })


if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", 8080), SetupHandler)
    print("Setup API listening on 127.0.0.1:8080")
    server.serve_forever()
