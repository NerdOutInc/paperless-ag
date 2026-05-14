#!/usr/bin/env python3
"""Setup wizard API for Paperless Ag 1-click image.

Handles form submission, generates config files, and kicks off
Docker Compose via finalize-setup.sh. Runs on localhost:8080,
proxied by host Caddy.

No pip dependencies -- stdlib only.
"""

import json
import errno
import re
import secrets
import socket
import string
import subprocess
import threading
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

BASE_DIR = Path("/opt/paperless-ag")
TEMPLATES_DIR = BASE_DIR / "templates"
SETUP_STATE_FILE = BASE_DIR / ".setup-state"
SETUP_TOKEN_FILE = BASE_DIR / ".setup-token"
MAX_BODY_SIZE = 65536  # 64 KB -- plenty for the setup JSON payload

# Valid IANA timezones are in /usr/share/zoneinfo -- we check against it
ZONEINFO = Path("/usr/share/zoneinfo")

# Validation patterns -- strict allowlists prevent injection into .env
# (single-quoted), docker-compose.yml (double-quoted YAML), and Caddyfile.
_USERNAME_RE = re.compile(r'^[a-zA-Z0-9_.\-]+$')
_DOMAIN_RE = re.compile(
    r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?'
    r'(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)+$'
)
_EMAIL_RE = re.compile(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
_MODEL_RE = re.compile(r'^[A-Za-z0-9][A-Za-z0-9._/-]*(:[A-Za-z0-9][A-Za-z0-9._-]*)?$')
# Characters unsafe in single-quoted .env, double-quoted YAML, shell contexts,
# or {{KEY}} template placeholders
_UNSAFE_VALUE_RE = re.compile(r"['\"\\\n\r\x00`${}]")


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


def get_total_ram_mb():
    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as meminfo:
            for line in meminfo:
                if line.startswith("MemTotal:"):
                    return int(line.split()[1]) // 1024
    except Exception:
        return 0
    return 0


def normalize_arch():
    try:
        raw = subprocess.check_output(["uname", "-m"], timeout=2).decode().strip()
    except Exception:
        raw = "unknown"
    if raw in ("x86_64", "amd64"):
        return "amd64"
    if raw in ("aarch64", "arm64"):
        return "arm64"
    return "unknown"


def recommended_model(ram_mb):
    if ram_mb >= 32768:
        return "qwen3:8b"
    if ram_mb >= 16000:
        return "qwen3:8b"
    if ram_mb >= 8000:
        return "llama3.2:3b"
    return ""


def model_options(ram_mb):
    if ram_mb < 8000:
        return ["", "llama3.2:1b"]
    if ram_mb < 16000:
        return ["llama3.2:3b", "gemma3:4b", ""]
    if ram_mb < 32768:
        return ["qwen3:8b", "gemma3:4b", ""]
    return ["qwen3:8b", "qwen3:14b", "gemma3:4b", ""]


def get_server_ip():
    try:
        return subprocess.check_output(
            ["curl", "-sf", "-4", "http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address"],
            timeout=5,
        ).decode().strip()
    except Exception:
        try:
            return subprocess.check_output(["hostname", "-I"], timeout=2).decode().split()[0]
        except Exception:
            return "localhost"


def dash_ip(ip):
    return ip.replace(".", "-")


def port_available(port):
    for host in ("0.0.0.0", "::"):
        family = socket.AF_INET6 if host == "::" else socket.AF_INET
        sock = socket.socket(family, socket.SOCK_STREAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind((host, port))
        except OSError as exc:
            if exc.errno in (errno.EAFNOSUPPORT, errno.EADDRNOTAVAIL) and host == "::":
                continue
            return False
        finally:
            sock.close()
    return True


def find_available_port(start=4000, end=4099):
    for port in range(start, end + 1):
        if port_available(port):
            return port
    raise RuntimeError(f"no available Open WebUI port found between {start}-{end}")


def build_tool_server_connections_json(mcp_token):
    return json.dumps(
        [{
            "type": "mcp",
            "url": "http://companion:3001/mcp",
            "path": "",
            "auth_type": "bearer",
            "key": mcp_token,
            "config": {"enable": True, "access_control": None},
            "info": {
                "id": "paperless-ag",
                "name": "Paperless Ag",
                "description": "Search Paperless documents through Paperless Ag.",
            },
        }],
        separators=(",", ":"),
    )


def build_local_ai_blocks(enabled, values):
    if not enabled:
        return {
            "LOCAL_AI_SERVICES": "",
            "LOCAL_AI_VOLUMES": "",
            "LOCAL_AI_CADDY_DEPENDS": "",
            "LOCAL_AI_CADDY_IP_BLOCK": "",
            "LOCAL_AI_CADDY_DOMAIN_BLOCK": "",
        }

    services = f"""
  ollama:
    image: ollama/ollama:latest
    restart: unless-stopped
    volumes:
      - ollama:/root/.ollama

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    restart: unless-stopped
    depends_on:
      - ollama
      - companion
    ports:
      - "${{OPEN_WEBUI_PORT_MAPPING}}"
    environment:
      OLLAMA_BASE_URL: http://ollama:11434
      WEBUI_SECRET_KEY: ${{WEBUI_SECRET_KEY}}
      WEBUI_AUTH: "True"
      ENABLE_DIRECT_CONNECTIONS: "True"
      BYPASS_ADMIN_ACCESS_CONTROL: "True"
      WEBUI_URL: ${{OPEN_WEBUI_URL}}
      TOOL_SERVER_CONNECTIONS: >-
        {values["TOOL_SERVER_CONNECTIONS"]}
    volumes:
      - open-webui:/app/backend/data
"""
    caddy_domain_block = ""
    caddy_ip_block = ""
    if values.get("AI_DOMAIN"):
        caddy_domain_block = f"""{values["AI_DOMAIN"]} {{
    tls {values["LE_EMAIL"]}
    reverse_proxy open-webui:8080
}}

"""
    elif values.get("LOCAL_AI_HTTP_EXPOSE") == "true":
        caddy_ip_block = """http://ai.*.sslip.io {
    reverse_proxy open-webui:8080
}

"""

    return {
        "LOCAL_AI_SERVICES": services,
        "LOCAL_AI_VOLUMES": "\n  ollama:\n  open-webui:",
        "LOCAL_AI_CADDY_DEPENDS": "\n      - open-webui",
        "LOCAL_AI_CADDY_IP_BLOCK": caddy_ip_block,
        "LOCAL_AI_CADDY_DOMAIN_BLOCK": caddy_domain_block,
    }


def get_state():
    """Read current setup state."""
    if SETUP_STATE_FILE.exists():
        return SETUP_STATE_FILE.read_text().strip()
    return "pending"


def set_state(state):
    """Write setup state."""
    SETUP_STATE_FILE.write_text(state)


def check_setup_token(provided):
    """Verify the provided token matches the one generated at first boot."""
    if not SETUP_TOKEN_FILE.exists():
        # Fail closed in production. Set PAPERLESS_SKIP_SETUP_TOKEN=1 for
        # local development without a token file.
        import os
        return os.environ.get("PAPERLESS_SKIP_SETUP_TOKEN") == "1"
    expected = SETUP_TOKEN_FILE.read_text().strip()
    return secrets.compare_digest(provided, expected)


class SetupHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        """Suppress default access logs."""
        pass

    def _send_json(self, status, data):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_GET(self):
        if self.path == "/api/status":
            self._send_json(200, {"state": get_state()})
        elif self.path == "/api/system":
            ram_mb = get_total_ram_mb()
            self._send_json(200, {
                "ram_mb": ram_mb,
                "arch": normalize_arch(),
                "recommended_model": recommended_model(ram_mb),
                "model_options": model_options(ram_mb),
            })
        else:
            self._send_json(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/api/setup":
            self._send_json(404, {"error": "not found"})
            return

        state = get_state()
        if state == "in_progress":
            # Allow retry if state has been stuck for over 10 minutes
            # (e.g. API crashed after setting state but before finalize ran)
            try:
                age = time.time() - SETUP_STATE_FILE.stat().st_mtime
            except OSError:
                age = 0
            if age < 600:
                self._send_json(409, {"error": "setup already in progress"})
                return
            # Stale in_progress -- fall through to allow retry
        if state == "complete":
            self._send_json(409, {"error": "setup already complete"})
            return
        # Allow retry from "pending", "failed", or stale "in_progress" state

        # Read request body
        try:
            length = int(self.headers.get("Content-Length", 0))
        except (ValueError, TypeError):
            self._send_json(400, {"error": "invalid Content-Length"})
            return
        if length > MAX_BODY_SIZE:
            self._send_json(413, {"error": "request body too large"})
            return
        body = self.rfile.read(length)
        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            self._send_json(400, {"error": "invalid JSON"})
            return

        # Verify one-time setup token (generated at first boot)
        setup_token = data.get("setup_token", "")
        if not check_setup_token(setup_token):
            self._send_json(403, {"error": "invalid setup token"})
            return

        # Validate required fields
        admin_user = data.get("admin_user", "").strip()
        admin_password = data.get("admin_password", "").strip()
        timezone = data.get("timezone", "").strip()
        domain = data.get("domain", "").strip()
        le_email = data.get("le_email", "").strip()
        local_ai_enabled = bool(data.get("local_ai_enabled", False))
        ai_domain = data.get("ai_domain", "").strip()
        expose_ai_http = bool(data.get("expose_ai_http", False))
        ollama_model = data.get("ollama_model", "").strip()
        pull_model = bool(data.get("pull_model", False))

        errors = []
        if not admin_user:
            errors.append("admin_user is required")
        elif not _USERNAME_RE.match(admin_user) or len(admin_user) > 150:
            errors.append("admin_user must contain only letters, digits, . _ - (max 150)")
        if not admin_password:
            errors.append("admin_password is required")
        elif len(admin_password) < 8:
            errors.append("admin_password must be at least 8 characters")
        elif _UNSAFE_VALUE_RE.search(admin_password):
            errors.append("admin_password cannot contain quotes, backslashes, backticks, $, {, }, or newlines")
        if not timezone or not valid_timezone(timezone):
            errors.append("valid timezone is required")
        if domain:
            if not _DOMAIN_RE.match(domain) or len(domain) > 253:
                errors.append("domain must be a valid hostname")
            if not le_email:
                errors.append("le_email is required when domain is provided")
            elif not _EMAIL_RE.match(le_email) or len(le_email) > 254:
                errors.append("le_email must be a valid email address")
        if ai_domain:
            if not local_ai_enabled:
                errors.append("ai_domain requires local_ai_enabled")
            elif not domain:
                errors.append("ai_domain requires a primary domain")
            elif not _DOMAIN_RE.match(ai_domain) or len(ai_domain) > 253:
                errors.append("ai_domain must be a valid hostname")
        if ollama_model and (not _MODEL_RE.match(ollama_model) or len(ollama_model) > 120):
            errors.append("ollama_model must be a valid Ollama model name")
        if pull_model and not ollama_model:
            errors.append("pull_model requires ollama_model")

        if errors:
            self._send_json(400, {"errors": errors})
            return

        set_state("in_progress")

        try:
            # Generate secrets
            db_password = generate_secret(32)
            secret_key = generate_secret(50)
            mcp_token = generate_secret(32)
            webui_secret_key = generate_secret(50)
            open_webui_host_port = str(find_available_port()) if local_ai_enabled else ""
            tool_server_connections = build_tool_server_connections_json(mcp_token)

            # Determine Paperless URL
            if domain:
                paperless_url = f"https://{domain}"
                server_ip = get_server_ip()
            else:
                server_ip = get_server_ip()
                paperless_url = f"http://{server_ip}"

            open_webui_host_bind = "127.0.0.1"
            open_webui_port_mapping = f"127.0.0.1:{open_webui_host_port}:8080" if local_ai_enabled else ""
            open_webui_url = ""
            open_webui_fallback_url = ""
            local_ai_http_expose = "false"
            if local_ai_enabled:
                if ai_domain:
                    open_webui_url = f"https://{ai_domain}"
                    open_webui_fallback_url = f"http://127.0.0.1:{open_webui_host_port}"
                elif not domain and expose_ai_http:
                    open_webui_host_bind = "0.0.0.0"
                    open_webui_port_mapping = f"{open_webui_host_port}:8080"
                    local_ai_http_expose = "true"
                    open_webui_url = f"http://ai.{dash_ip(server_ip)}.sslip.io"
                    open_webui_fallback_url = f"http://{server_ip}:{open_webui_host_port}"
                else:
                    open_webui_url = f"http://127.0.0.1:{open_webui_host_port}"
                    open_webui_fallback_url = open_webui_url

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
                "LOCAL_AI_ENABLED": "true" if local_ai_enabled else "false",
                "LOCAL_AI_HTTP_EXPOSE": local_ai_http_expose,
                "AI_DOMAIN": ai_domain,
                "WEBUI_SECRET_KEY": webui_secret_key if local_ai_enabled else "",
                "OPEN_WEBUI_HOST_PORT": open_webui_host_port if local_ai_enabled else "",
                "OPEN_WEBUI_HOST_BIND": open_webui_host_bind if local_ai_enabled else "",
                "OPEN_WEBUI_PORT_MAPPING": open_webui_port_mapping if local_ai_enabled else "",
                "OPEN_WEBUI_URL": open_webui_url,
                "OPEN_WEBUI_FALLBACK_URL": open_webui_fallback_url,
                "OLLAMA_DEFAULT_MODEL": ollama_model,
                "OLLAMA_PULL_MODEL_ON_INSTALL": "true" if pull_model else "false",
                "TOOL_SERVER_CONNECTIONS": tool_server_connections,
            }
            variables.update(build_local_ai_blocks(local_ai_enabled, variables))

            # Render config files
            env_content = render_template(
                TEMPLATES_DIR / "env.template", variables
            )

            if domain:
                caddy_content = render_template(
                    TEMPLATES_DIR / "Caddyfile.domain.tpl", variables
                )
            else:
                caddy_content = render_template(
                    TEMPLATES_DIR / "Caddyfile.ip.tpl", variables
                )

            # Write config files -- .env is the single source of truth for
            # secrets; docker-compose.yml uses ${...} references into it.
            env_path = BASE_DIR / ".env"
            env_path.write_text(env_content)
            env_path.chmod(0o600)

            compose_path = BASE_DIR / "docker-compose.yml"
            compose_path.write_text(
                render_template(TEMPLATES_DIR / "docker-compose.yml.tpl", variables)
            )

            (BASE_DIR / "Caddyfile").write_text(caddy_content)
        except Exception as exc:
            set_state("failed")
            log_path = BASE_DIR / "setup.log"
            log_path.write_text(f"Config generation failed: {exc}\n")
            self._send_json(500, {
                "error": "Setup failed during config generation. Check setup.log for details."
            })
            return

        # Run finalize in background so we can return the response
        # before the host Caddy shuts down.  State transitions are
        # written by finalize-setup.sh itself (this daemon thread is
        # killed by SIGTERM before it could write them).
        def finalize():
            log_path = BASE_DIR / "setup.log"
            with open(log_path, "w") as log:
                subprocess.run(
                    ["/opt/paperless-ag/scripts/finalize-setup.sh"],
                    stdout=log,
                    stderr=subprocess.STDOUT,
                )

        threading.Thread(target=finalize, daemon=True).start()

        self._send_json(200, {
            "status": "started",
            "mcp_token": mcp_token,
            "paperless_url": paperless_url,
            "mcp_url": f"{paperless_url}/mcp",
            "local_ai_enabled": local_ai_enabled,
            "open_webui_url": open_webui_url,
            "open_webui_fallback_url": open_webui_fallback_url,
            "ollama_model": ollama_model,
            "tool_server_connections": tool_server_connections,
        })


if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", 8080), SetupHandler)
    print("Setup API listening on 127.0.0.1:8080")
    server.serve_forever()
