#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# Paperless Ag Installer
# https://github.com/NerdOutInc/paperless-ag
#
# Usage: curl -fsSL https://paperless.fullstack.ag/install.sh | bash
# ─────────────────────────────────────────────────────────

COMPANION_IMAGE="ghcr.io/nerdoutinc/paperless-ag:latest"
OPEN_WEBUI_IMAGE="ghcr.io/open-webui/open-webui:main"
OLLAMA_IMAGE="ollama/ollama:latest"
MIN_DISK_GB=5
MIN_RAM_MB=3900
RECOMMENDED_RAM_MB=3900
LOCAL_AI_PORT_START=4000
LOCAL_AI_PORT_END=4099

# ── Colors ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()  { echo -e "  ${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "  ${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "  ${RED}[✗]${NC} $1"; }
step()  { echo -e "  ${BLUE}[…]${NC} $1"; }

banner() {
    echo
    echo -e "${BOLD}════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  Paperless Ag Setup${NC}"
    echo -e "${DIM}  Semantic search for Paperless-ngx${NC}"
    echo -e "${BOLD}════════════════════════════════════════════════════${NC}"
    echo
}

divider() {
    echo
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
    echo
}

# ── Prompts ──────────────────────────────────────────────

prompt() {
    local prompt_text="$1" default="${2:-}"
    local input
    if [[ -n "$default" ]]; then
        read -rp "  $prompt_text [$default]: " input < /dev/tty
        echo "${input:-$default}"
    else
        read -rp "  $prompt_text: " input < /dev/tty
        echo "$input"
    fi
}

prompt_safe() {
    # Like prompt, but rejects characters that break .env or YAML files
    local prompt_text="$1" default="${2:-}" result=""
    while true; do
        result=$(prompt "$prompt_text" "$default")
        if [[ -z "$result" ]]; then
            echo "$result"
            return
        fi
        if [[ "$result" =~ [\'\"\`\\\$\#] ]] || [[ "$result" == *$'\n'* ]]; then
            warn "Cannot contain quotes, backticks, backslashes, \$, or # characters." >&2
            continue
        fi
        echo "$result"
        return
    done
}

prompt_required() {
    local prompt_text="$1" result=""
    while [[ -z "$result" ]]; do
        result=$(prompt_safe "$prompt_text")
        [[ -z "$result" ]] && warn "This field is required."
    done
    echo "$result"
}

prompt_domain() {
    local prompt_text="$1" result=""
    while true; do
        result=$(prompt "$prompt_text")
        [[ -z "$result" ]] && echo "" && return
        if [[ "$result" =~ ^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$ ]]; then
            echo "$result"
            return
        fi
        warn "Domain must contain only letters, numbers, dots, and hyphens." >&2
    done
}

prompt_secret() {
    local prompt_text="$1" result=""
    while [[ -z "$result" ]]; do
        read -srp "  $prompt_text: " result < /dev/tty
        echo >&2
        if [[ -z "$result" ]]; then
            warn "This field is required." >&2
            continue
        fi
        if [[ "$result" =~ [\'\"\`\\\$\#] ]]; then
            warn "Password cannot contain single quotes, double quotes, backticks, backslashes, \$ or # characters." >&2
            result=""
            continue
        fi
        local confirm
        read -srp "  Confirm password: " confirm < /dev/tty
        echo >&2
        if [[ "$result" != "$confirm" ]]; then
            warn "Passwords don't match. Try again." >&2
            result=""
        fi
    done
    echo "$result"
}

run_quiet() {
    # Run a command, suppress output on success, show full output on failure
    local output
    if output=$("$@" 2>&1); then
        return 0
    else
        echo "$output" >&2
        return 1
    fi
}

prompt_yn() {
    local prompt_text="$1" default="${2:-y}"
    local yn_hint="[Y/n]"
    [[ "$default" == "n" ]] && yn_hint="[y/N]"
    local input
    read -rp "  $prompt_text $yn_hint: " input < /dev/tty
    input="${input:-$default}"
    [[ "${input,,}" == "y" ]]
}

generate_password() {
    if command -v openssl &>/dev/null; then
        openssl rand -base64 32 | tr -d '/+=' | head -c 32
    elif command -v base64 &>/dev/null; then
        head -c 48 /dev/urandom | base64 | tr -d '/+=' | head -c 32
    else
        fail "Neither openssl nor base64 is available for generating passwords."
        exit 1
    fi
}

detect_total_ram_mb() {
    free -m 2>/dev/null | awk '/Mem:/ {print $2}' || echo "0"
}

detect_arch() {
    case "$(uname -m 2>/dev/null || echo unknown)" in
        x86_64 | amd64) echo "amd64" ;;
        aarch64 | arm64) echo "arm64" ;;
        *) echo "unknown" ;;
    esac
}

detect_gpu_hint() {
    if command -v nvidia-smi &>/dev/null; then
        echo "nvidia"
    elif [[ -e /dev/dri/renderD128 ]] || lspci 2>/dev/null | grep -Eiq 'vga|3d|display'; then
        echo "present"
    else
        echo "none"
    fi
}

model_download_size() {
    case "$1" in
        qwen3:0.6b) echo "about 523MB" ;;
        gemma3:270m) echo "about 292MB" ;;
        smollm2:360m) echo "about 726MB" ;;
        gemma3:1b) echo "about 815MB" ;;
        gemma3:4b) echo "about 3.3GB" ;;
        qwen3:8b) echo "about 5.2GB" ;;
        qwen3:14b) echo "about 9.3GB" ;;
        *) echo "size varies" ;;
    esac
}

recommended_local_ai_model() {
    local ram_mb="$1"
    if (( ram_mb >= 32768 )); then
        echo "qwen3:8b"
    elif (( ram_mb >= 16000 )); then
        echo "qwen3:8b"
    elif (( ram_mb >= 7000 )); then
        echo "qwen3:0.6b"
    else
        echo ""
    fi
}

validate_model_name() {
    local model="$1"
    [[ "$model" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*(:[A-Za-z0-9][A-Za-z0-9._-]*)?$ ]]
}

prompt_model_name() {
    local default_model="$1" result=""
    while true; do
        result=$(prompt "Ollama model" "$default_model")
        if validate_model_name "$result"; then
            echo "$result"
            return
        fi
        warn "Use a valid Ollama model name like qwen3:0.6b, gemma3:1b, or qwen3:8b." >&2
    done
}

port_available() {
    local port="$1"
    if command -v python3 &>/dev/null; then
        python3 - "$port" <<'PY'
import errno
import socket
import sys

port = int(sys.argv[1])
for host in ("0.0.0.0", "::"):
    family = socket.AF_INET6 if host == "::" else socket.AF_INET
    sock = socket.socket(family, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        sock.bind((host, port))
    except OSError as exc:
        if exc.errno in (errno.EAFNOSUPPORT, errno.EADDRNOTAVAIL) and host == "::":
            continue
        sys.exit(1)
    finally:
        sock.close()
sys.exit(0)
PY
        return $?
    fi

    ! ss -tln 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]${port}$"
}

find_available_port() {
    local port
    for (( port = LOCAL_AI_PORT_START; port <= LOCAL_AI_PORT_END; port++ )); do
        if port_available "$port"; then
            echo "$port"
            return
        fi
    done
    fail "No available Open WebUI port found between ${LOCAL_AI_PORT_START}-${LOCAL_AI_PORT_END}."
    exit 1
}

dash_ip() {
    echo "$1" | tr . -
}

build_tool_server_connections_json() {
    local token="$1"
    printf '[{"type":"mcp","url":"http://companion:3001/mcp","path":"","auth_type":"bearer","key":"%s","config":{"enable":true,"access_control":null},"info":{"id":"paperless-ag","name":"Paperless Ag","description":"Search Paperless documents through Paperless Ag."}}]' "$token"
}

# ── System Checks ────────────────────────────────────────

check_platform() {
    if [[ "$(uname -s)" != "Linux" ]]; then
        fail "This installer is designed for Linux servers."
        echo "  For local development on macOS/Windows, see:"
        echo "  https://github.com/NerdOutInc/paperless-ag#local-development"
        exit 1
    fi
}

check_docker() {
    if ! command -v docker &>/dev/null; then
        fail "Docker is not installed."
        echo
        if prompt_yn "Install Docker now?"; then
            step "Installing Docker (this may take a minute)..."
            local tmp_docker_install
            tmp_docker_install="$(mktemp)"
            if ! curl -fsSL https://get.docker.com -o "$tmp_docker_install"; then
                rm -f "$tmp_docker_install"
                fail "Failed to download Docker install script."
                echo "  Install Docker manually: https://docs.docker.com/engine/install/"
                exit 1
            fi
            local sh_cmd="sh"
            [[ $EUID -ne 0 ]] && sh_cmd="sudo sh"
            if ! $sh_cmd "$tmp_docker_install"; then
                rm -f "$tmp_docker_install"
                fail "Docker installation failed."
                echo "  Install Docker manually: https://docs.docker.com/engine/install/"
                exit 1
            fi
            rm -f "$tmp_docker_install"
            info "Docker installed."

            # Add current user to docker group if not root
            if [[ $EUID -ne 0 ]]; then
                sudo usermod -aG docker "$USER"
                echo
                warn "You've been added to the 'docker' group."
                warn "Please log out and back in, then run this script again."
                exit 0
            fi
        else
            fail "Docker is required. Install it and try again:"
            echo "  https://docs.docker.com/engine/install/"
            exit 1
        fi
    fi

    if ! docker compose version &>/dev/null; then
        fail "Docker Compose v2 is required but not found."
        echo "  Update Docker or install the compose plugin:"
        echo "  https://docs.docker.com/compose/install/"
        exit 1
    fi

    # Check daemon is running
    if ! docker info &>/dev/null; then
        if [[ $EUID -ne 0 ]]; then
            # Maybe user isn't in docker group
            if groups "$USER" 2>/dev/null | grep -q docker; then
                fail "Docker daemon is not running. Try: sudo systemctl start docker"
            else
                fail "Your user is not in the 'docker' group."
                if prompt_yn "Add yourself to the docker group now?"; then
                    sudo usermod -aG docker "$USER"
                    warn "Added to docker group. Log out and back in, then re-run this script."
                    exit 0
                fi
            fi
        else
            fail "Docker daemon is not running. Try: systemctl start docker"
        fi
        exit 1
    fi

    info "Docker $(docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo '(version unknown)')"
    info "Docker Compose $(docker compose version --short 2>/dev/null || echo '(version unknown)')"
}

check_resources() {
    # Disk space
    local free_gb
    free_gb=$(df -BG --output=avail "$HOME" 2>/dev/null | tail -1 | tr -d ' G' || echo "0")
    if (( free_gb > 0 )); then
        if (( free_gb < MIN_DISK_GB )); then
            fail "Not enough disk space. Need ${MIN_DISK_GB}GB free, have ${free_gb}GB."
            exit 1
        fi
        info "${free_gb}GB disk space available"
    fi

    # RAM
    local total_ram_mb
    total_ram_mb=$(detect_total_ram_mb)
    TOTAL_RAM_MB="$total_ram_mb"
    if (( total_ram_mb > 0 )); then
        if (( total_ram_mb < MIN_RAM_MB )); then
            fail "Not enough RAM. Need at least 4GB, have ${total_ram_mb}MB."
            fail "Paperless + the embedding model need at least 4GB to run well."
            exit 1
        elif (( total_ram_mb < RECOMMENDED_RAM_MB )); then
            warn "${total_ram_mb}MB RAM. 4GB+ recommended for best performance."
        else
            info "${total_ram_mb}MB RAM available"
        fi
    fi
}

check_ports() {
    local blocked=""
    for port in 80 443; do
        if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
            blocked="${blocked} ${port}"
        fi
    done
    if [[ -n "$blocked" ]]; then
        warn "Port(s)${blocked} already in use."
        warn "Another web server may be running (nginx, apache, etc.)."
        warn "Caddy needs ports 80 and 443 for HTTPS."
        if ! prompt_yn "Continue anyway?" "n"; then
            exit 0
        fi
    fi
}

# Read a variable from a file (docker-compose.yml, .env, or env_file).
# Usage: read_var_from_file "VARNAME" "/path/to/file"
# Matches: VARNAME=value, VARNAME: value, VARNAME='value', VARNAME="value"
read_var_from_file() {
    local varname="$1" filepath="$2"
    [[ -f "$filepath" ]] || return 1
    local raw
    raw=$(grep -E "^\s*${varname}[=:]" "$filepath" 2>/dev/null | head -1) || return 1
    [[ -z "$raw" ]] && return 1
    # Strip key and separator (= or :), then trim whitespace and quotes
    local value
    value=$(echo "$raw" | sed -E "s/^[^=:]*[=:]\s*//" | sed -E "s/^['\"]//;s/['\"]$//")
    [[ -z "$value" ]] && return 1
    echo "$value"
}

# ── Detect Existing Paperless ────────────────────────────

detect_paperless() {
    # Look for running Paperless containers
    local container_id=""

    # Try by image name first
    container_id=$(docker ps --filter "ancestor=ghcr.io/paperless-ngx/paperless-ngx" --format "{{.ID}}" 2>/dev/null | head -1)

    # Fall back to name pattern
    if [[ -z "$container_id" ]]; then
        container_id=$(docker ps --format "{{.ID}} {{.Image}}" 2>/dev/null | grep -i "paperless-ngx" | awk '{print $1}' | head -1)
    fi

    if [[ -z "$container_id" ]]; then
        return 1
    fi

    PAPERLESS_CONTAINER_ID="$container_id"
    PAPERLESS_COMPOSE_DIR=$(docker inspect "$container_id" --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' 2>/dev/null || echo "")
    PAPERLESS_COMPOSE_PROJECT=$(docker inspect "$container_id" --format '{{index .Config.Labels "com.docker.compose.project"}}' 2>/dev/null || echo "")
    PAPERLESS_SERVICE_NAME=$(docker inspect "$container_id" --format '{{index .Config.Labels "com.docker.compose.service"}}' 2>/dev/null || echo "paperless-webserver")

    # ── DB credentials cascade ──────────────────────────────
    # Source 1: Paperless container env
    local env_output
    env_output=$(docker inspect "$container_id" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null || echo "")

    DETECTED_DB_HOST=$(echo "$env_output" | grep "^PAPERLESS_DBHOST=" | cut -d= -f2- || echo "")
    DETECTED_DB_NAME=$(echo "$env_output" | grep "^PAPERLESS_DBNAME=" | cut -d= -f2- || echo "")
    DETECTED_DB_USER=$(echo "$env_output" | grep "^PAPERLESS_DBUSER=" | cut -d= -f2- || echo "")
    DETECTED_DB_PASS=$(echo "$env_output" | grep "^PAPERLESS_DBPASS=" | cut -d= -f2- || echo "")

    # Source 2: Postgres container env (POSTGRES_PASSWORD, etc.)
    if [[ -z "$DETECTED_DB_PASS" ]] && [[ -n "${PAPERLESS_COMPOSE_PROJECT:-}" ]]; then
        local db_container
        db_container=$(docker ps --filter "label=com.docker.compose.project=${PAPERLESS_COMPOSE_PROJECT}" --format "{{.ID}} {{.Image}}" 2>/dev/null | grep -i "postgres\|pgvector" | awk '{print $1}' | head -1)
        if [[ -n "$db_container" ]]; then
            local db_env
            db_env=$(docker inspect "$db_container" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null || echo "")
            [[ -z "$DETECTED_DB_PASS" ]] && DETECTED_DB_PASS=$(echo "$db_env" | grep "^POSTGRES_PASSWORD=" | cut -d= -f2- || echo "")
            [[ -z "$DETECTED_DB_USER" ]] && DETECTED_DB_USER=$(echo "$db_env" | grep "^POSTGRES_USER=" | cut -d= -f2- || echo "")
            [[ -z "$DETECTED_DB_NAME" ]] && DETECTED_DB_NAME=$(echo "$db_env" | grep "^POSTGRES_DB=" | cut -d= -f2- || echo "")
        fi
    fi

    # Source 3: Compose file and env files on disk
    local compose_dir="${PAPERLESS_COMPOSE_DIR:-}"
    if [[ -z "$DETECTED_DB_PASS" ]] && [[ -n "$compose_dir" ]]; then
        # Try docker-compose.yml directly
        DETECTED_DB_PASS=$(read_var_from_file "PAPERLESS_DBPASS" "$compose_dir/docker-compose.yml" || echo "")
        [[ -z "$DETECTED_DB_PASS" ]] && DETECTED_DB_PASS=$(read_var_from_file "POSTGRES_PASSWORD" "$compose_dir/docker-compose.yml" || echo "")

        # Try .env file
        [[ -z "$DETECTED_DB_PASS" ]] && DETECTED_DB_PASS=$(read_var_from_file "PAPERLESS_DBPASS" "$compose_dir/.env" || echo "")
        [[ -z "$DETECTED_DB_PASS" ]] && DETECTED_DB_PASS=$(read_var_from_file "POSTGRES_PASSWORD" "$compose_dir/.env" || echo "")

        # Try env_file references (e.g., docker-compose.env)
        if [[ -z "$DETECTED_DB_PASS" ]]; then
            local env_files
            env_files=$(grep -E '^\s*-?\s*env_file:|^\s*-\s+' "$compose_dir/docker-compose.yml" 2>/dev/null | grep -oE '[a-zA-Z0-9._-]+\.env' || echo "")
            for ef in $env_files; do
                [[ -z "$DETECTED_DB_PASS" ]] && DETECTED_DB_PASS=$(read_var_from_file "PAPERLESS_DBPASS" "$compose_dir/$ef" || echo "")
                [[ -z "$DETECTED_DB_PASS" ]] && DETECTED_DB_PASS=$(read_var_from_file "POSTGRES_PASSWORD" "$compose_dir/$ef" || echo "")
            done
        fi
    fi

    # Defaults for anything not detected
    DETECTED_DB_HOST="${DETECTED_DB_HOST:-db}"
    DETECTED_DB_NAME="${DETECTED_DB_NAME:-paperless}"
    DETECTED_DB_USER="${DETECTED_DB_USER:-paperless}"

    # ── Paperless admin credentials cascade ─────────────────
    DETECTED_ADMIN_USER=$(echo "$env_output" | grep "^PAPERLESS_ADMIN_USER=" | cut -d= -f2- || echo "")
    DETECTED_ADMIN_PASS=$(echo "$env_output" | grep "^PAPERLESS_ADMIN_PASSWORD=" | cut -d= -f2- || echo "")

    if [[ -n "$compose_dir" ]]; then
        [[ -z "$DETECTED_ADMIN_USER" ]] && DETECTED_ADMIN_USER=$(read_var_from_file "PAPERLESS_ADMIN_USER" "$compose_dir/docker-compose.yml" || echo "")
        [[ -z "$DETECTED_ADMIN_PASS" ]] && DETECTED_ADMIN_PASS=$(read_var_from_file "PAPERLESS_ADMIN_PASSWORD" "$compose_dir/docker-compose.yml" || echo "")

        # Try .env file
        [[ -z "$DETECTED_ADMIN_USER" ]] && DETECTED_ADMIN_USER=$(read_var_from_file "PAPERLESS_ADMIN_USER" "$compose_dir/.env" || echo "")
        [[ -z "$DETECTED_ADMIN_PASS" ]] && DETECTED_ADMIN_PASS=$(read_var_from_file "PAPERLESS_ADMIN_PASSWORD" "$compose_dir/.env" || echo "")

        if [[ -z "$DETECTED_ADMIN_PASS" ]]; then
            local env_files
            env_files=$(grep -E '^\s*-?\s*env_file:|^\s*-\s+' "$compose_dir/docker-compose.yml" 2>/dev/null | grep -oE '[a-zA-Z0-9._-]+\.env' || echo "")
            for ef in $env_files; do
                [[ -z "$DETECTED_ADMIN_USER" ]] && DETECTED_ADMIN_USER=$(read_var_from_file "PAPERLESS_ADMIN_USER" "$compose_dir/$ef" || echo "")
                [[ -z "$DETECTED_ADMIN_PASS" ]] && DETECTED_ADMIN_PASS=$(read_var_from_file "PAPERLESS_ADMIN_PASSWORD" "$compose_dir/$ef" || echo "")
            done
        fi
    fi

    return 0
}

detect_pgvector() {
    # Check if the Postgres container has pgvector available
    local db_container=""

    if [[ -n "${PAPERLESS_COMPOSE_PROJECT:-}" ]]; then
        db_container=$(docker ps --filter "label=com.docker.compose.project=${PAPERLESS_COMPOSE_PROJECT}" --format "{{.ID}} {{.Image}}" 2>/dev/null | grep -i "postgres\|pgvector" | awk '{print $1}' | head -1)
    fi

    if [[ -z "$db_container" ]]; then
        return 1
    fi

    DB_CONTAINER_ID="$db_container"
    DB_IMAGE=$(docker inspect "$db_container" --format '{{.Config.Image}}' 2>/dev/null || echo "")

    # Extract Postgres major version from image tag
    # Handles: postgres:18, postgres:16.2, pgvector/pgvector:pg16, library/postgres:18-alpine
    DB_PG_MAJOR=""
    if [[ -n "$DB_IMAGE" ]]; then
        local tag="${DB_IMAGE##*:}"
        # Strip leading "pg" prefix (pgvector images use pg16, pg17, etc.)
        tag="${tag#pg}"
        # Extract leading digits as major version
        DB_PG_MAJOR=$(echo "$tag" | grep -oE '^[0-9]+')
    fi

    # Check if pgvector extension is available
    if docker exec "$db_container" psql -U "${DETECTED_DB_USER}" -d "${DETECTED_DB_NAME}" -c "SELECT 1 FROM pg_available_extensions WHERE name = 'vector'" 2>/dev/null | grep -q "1"; then
        return 0  # pgvector is available
    fi

    return 1
}

# ── Pre-Flight Validation ────────────────────────────────

validate_db_connection() {
    # Test that we can connect to Postgres with the detected/provided credentials
    local db_container="${DB_CONTAINER_ID:-}"
    local user="${DB_USER:-$DETECTED_DB_USER}"
    local name="${DB_NAME:-$DETECTED_DB_NAME}"
    local pass="${DB_PASS:-$DETECTED_DB_PASS}"

    if [[ -z "$db_container" ]]; then
        return 1
    fi

    if docker exec -e PGPASSWORD="$pass" "$db_container" \
        psql -U "$user" -d "$name" -c "SELECT 1" &>/dev/null; then
        return 0
    fi
    return 1
}

validate_paperless_api() {
    # Test that we can authenticate against the Paperless API
    local user="${ADMIN_USER:-}"
    local pass="${ADMIN_PASSWORD:-}"
    local paperless_url="http://localhost:8000"

    # Find the published port for the Paperless container
    if [[ -n "${PAPERLESS_CONTAINER_ID:-}" ]]; then
        local published_port
        published_port=$(docker inspect "$PAPERLESS_CONTAINER_ID" --format '{{range $p, $conf := .NetworkSettings.Ports}}{{if eq $p "8000/tcp"}}{{(index $conf 0).HostPort}}{{end}}{{end}}' 2>/dev/null || echo "")
        if [[ -n "$published_port" ]]; then
            paperless_url="http://localhost:${published_port}"
        fi
    fi

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "${paperless_url}/api/token/" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"${user}\",\"password\":\"${pass}\"}" 2>/dev/null || echo "000")

    [[ "$http_code" == "200" ]]
}

validate_pgvector_image() {
    # Verify that a pgvector image exists for the detected Postgres major version
    local pg_major="${DB_PG_MAJOR:-}"
    if [[ -z "$pg_major" ]]; then
        return 1
    fi

    PGVECTOR_IMAGE="pgvector/pgvector:pg${pg_major}"

    if docker manifest inspect "$PGVECTOR_IMAGE" &>/dev/null; then
        return 0
    fi
    return 1
}

choose_local_ai_model() {
    local ram_mb="${TOTAL_RAM_MB:-$(detect_total_ram_mb)}"
    local recommended
    recommended=$(recommended_local_ai_model "$ram_mb")

    echo "  Local AI model options"
    echo -e "  ${DIM}Detected: ${ram_mb:-0}MB RAM, $(detect_arch) CPU, GPU: $(detect_gpu_hint)${NC}"
    echo

    if (( ram_mb < 7000 )); then
        echo "    1) Skip model download (recommended for this machine)"
        echo "    2) gemma3:270m -- tiniest option ($(model_download_size gemma3:270m))"
        echo "    3) qwen3:0.6b -- better chat, still tiny ($(model_download_size qwen3:0.6b))"
        echo "    4) Use a custom Ollama model name"
        echo
        case "$(prompt "Choose" "1")" in
            2) OLLAMA_DEFAULT_MODEL="gemma3:270m" ;;
            3) OLLAMA_DEFAULT_MODEL="qwen3:0.6b" ;;
            4) OLLAMA_DEFAULT_MODEL=$(prompt_model_name "qwen3:0.6b") ;;
            *) OLLAMA_DEFAULT_MODEL="" ;;
        esac
    elif (( ram_mb < 16000 )); then
        echo "    1) ${recommended} -- recommended for this machine ($(model_download_size "$recommended"))"
        echo "    2) gemma3:1b -- slightly larger fallback ($(model_download_size gemma3:1b))"
        echo "    3) gemma3:270m -- fastest/smallest ($(model_download_size gemma3:270m))"
        echo "    4) smollm2:360m -- compact fallback ($(model_download_size smollm2:360m))"
        echo "    5) Skip model download"
        echo "    6) Use a custom Ollama model name"
        echo
        case "$(prompt "Choose" "1")" in
            2) OLLAMA_DEFAULT_MODEL="gemma3:1b" ;;
            3) OLLAMA_DEFAULT_MODEL="gemma3:270m" ;;
            4) OLLAMA_DEFAULT_MODEL="smollm2:360m" ;;
            5) OLLAMA_DEFAULT_MODEL="" ;;
            6) OLLAMA_DEFAULT_MODEL=$(prompt_model_name "$recommended") ;;
            *) OLLAMA_DEFAULT_MODEL="$recommended" ;;
        esac
    elif (( ram_mb < 32768 )); then
        echo "    1) ${recommended} -- recommended for this machine ($(model_download_size "$recommended"))"
        echo "    2) gemma3:4b -- faster/lighter ($(model_download_size gemma3:4b))"
        echo "    3) Skip model download"
        echo "    4) Use a custom Ollama model name"
        echo
        case "$(prompt "Choose" "1")" in
            2) OLLAMA_DEFAULT_MODEL="gemma3:4b" ;;
            3) OLLAMA_DEFAULT_MODEL="" ;;
            4) OLLAMA_DEFAULT_MODEL=$(prompt_model_name "$recommended") ;;
            *) OLLAMA_DEFAULT_MODEL="$recommended" ;;
        esac
    else
        echo "    1) ${recommended} -- recommended default ($(model_download_size "$recommended"))"
        echo "    2) qwen3:14b -- higher quality, larger/slower ($(model_download_size qwen3:14b))"
        echo "    3) gemma3:4b -- faster/lighter ($(model_download_size gemma3:4b))"
        echo "    4) Skip model download"
        echo "    5) Use a custom Ollama model name"
        echo
        case "$(prompt "Choose" "1")" in
            2) OLLAMA_DEFAULT_MODEL="qwen3:14b" ;;
            3) OLLAMA_DEFAULT_MODEL="gemma3:4b" ;;
            4) OLLAMA_DEFAULT_MODEL="" ;;
            5) OLLAMA_DEFAULT_MODEL=$(prompt_model_name "$recommended") ;;
            *) OLLAMA_DEFAULT_MODEL="$recommended" ;;
        esac
    fi

    if [[ -n "${OLLAMA_DEFAULT_MODEL:-}" ]]; then
        echo
        echo "  Selected model: ${OLLAMA_DEFAULT_MODEL} ($(model_download_size "$OLLAMA_DEFAULT_MODEL"))"
        if prompt_yn "Download this model during setup?" "y"; then
            OLLAMA_PULL_MODEL_ON_INSTALL="true"
        else
            OLLAMA_PULL_MODEL_ON_INSTALL="false"
        fi
    else
        OLLAMA_PULL_MODEL_ON_INSTALL="false"
    fi
}

collect_local_ai_config() {
    LOCAL_AI_ENABLED="false"
    LOCAL_AI_HTTP_EXPOSE="false"
    WEBUI_SECRET_KEY=""
    OPEN_WEBUI_HOST_PORT=""
    OPEN_WEBUI_HOST_BIND="127.0.0.1"
    OPEN_WEBUI_PORT_MAPPING=""
    OPEN_WEBUI_URL=""
    OPEN_WEBUI_FALLBACK_URL=""
    AI_DOMAIN=""
    OLLAMA_DEFAULT_MODEL=""
    OLLAMA_PULL_MODEL_ON_INSTALL="false"
    OPEN_WEBUI_DEFAULT_MODEL_PARAMS=""

    divider
    echo "  Optional local AI chat"
    echo "  This adds Ollama and Open WebUI so a local model can use"
    echo "  Paperless Ag through MCP. Paperless semantic embeddings stay unchanged."
    echo
    if ! prompt_yn "Install local AI chat?" "n"; then
        return
    fi

    LOCAL_AI_ENABLED="true"
    WEBUI_SECRET_KEY=$(generate_password)
    OPEN_WEBUI_HOST_PORT=$(find_available_port)

    if [[ -n "${DOMAIN:-}" ]]; then
        echo
        echo "  Open WebUI should use its own HTTPS hostname."
        echo -e "  ${DIM}(e.g., ai.smithfarms.com, already pointed at this server)${NC}"
        echo
        AI_DOMAIN=$(prompt_domain "AI domain (or press Enter to skip public AI URL)")
        if [[ -n "$AI_DOMAIN" ]]; then
            OPEN_WEBUI_URL="https://${AI_DOMAIN}"
        else
            warn "Open WebUI will only be available through an SSH tunnel to localhost:${OPEN_WEBUI_HOST_PORT}."
            OPEN_WEBUI_URL="http://127.0.0.1:${OPEN_WEBUI_HOST_PORT}"
        fi
        OPEN_WEBUI_HOST_BIND="127.0.0.1"
    else
        warn "Without a domain, Open WebUI is served over plain HTTP if exposed."
        warn "Only expose it this way on a trusted home/LAN network."
        if prompt_yn "Expose Open WebUI over HTTP on this server/LAN?" "n"; then
            LOCAL_AI_HTTP_EXPOSE="true"
            OPEN_WEBUI_HOST_BIND="0.0.0.0"
            local detected_ip
            detected_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
            if [[ -n "$detected_ip" ]]; then
                OPEN_WEBUI_URL="http://ai.$(dash_ip "$detected_ip").sslip.io"
                OPEN_WEBUI_FALLBACK_URL="http://${detected_ip}:${OPEN_WEBUI_HOST_PORT}"
            else
                OPEN_WEBUI_URL="http://localhost:${OPEN_WEBUI_HOST_PORT}"
                OPEN_WEBUI_FALLBACK_URL="$OPEN_WEBUI_URL"
            fi
        else
            OPEN_WEBUI_URL="http://127.0.0.1:${OPEN_WEBUI_HOST_PORT}"
            OPEN_WEBUI_FALLBACK_URL="$OPEN_WEBUI_URL"
        fi
    fi

    if [[ "$OPEN_WEBUI_HOST_BIND" == "127.0.0.1" ]]; then
        OPEN_WEBUI_PORT_MAPPING="127.0.0.1:${OPEN_WEBUI_HOST_PORT}:8080"
        OPEN_WEBUI_FALLBACK_URL="${OPEN_WEBUI_FALLBACK_URL:-http://127.0.0.1:${OPEN_WEBUI_HOST_PORT}}"
    else
        OPEN_WEBUI_PORT_MAPPING="${OPEN_WEBUI_HOST_PORT}:8080"
    fi

    choose_local_ai_model
    if [[ "${OLLAMA_DEFAULT_MODEL:-}" == "qwen3" || "${OLLAMA_DEFAULT_MODEL:-}" == qwen3:* ]]; then
        OPEN_WEBUI_DEFAULT_MODEL_PARAMS='{"think":false}'
    fi
}

# ── Collect Configuration ────────────────────────────────

collect_fresh_config() {
    echo "  Let's set up your Paperless Ag instance."
    divider

    ADMIN_USER=$(prompt_safe "Admin username" "admin")
    ADMIN_PASSWORD=$(prompt_secret "Admin password")

    divider

    echo "  What timezone are you in?"
    echo
    echo "    1) US/Central"
    echo "    2) US/Eastern"
    echo "    3) US/Mountain"
    echo "    4) US/Pacific"
    echo "    5) Other"
    echo
    local tz_choice
    tz_choice=$(prompt "Choose" "1")
    case "$tz_choice" in
        1) TIMEZONE="America/Chicago" ;;
        2) TIMEZONE="America/New_York" ;;
        3) TIMEZONE="America/Denver" ;;
        4) TIMEZONE="America/Los_Angeles" ;;
        *)
            TIMEZONE=$(prompt_safe "Enter timezone (e.g. Europe/London)" "America/Chicago")
            ;;
    esac

    divider

    echo "  Do you have a domain name pointed at this server?"
    echo -e "  ${DIM}(e.g., docs.smithfarms.com)${NC}"
    echo
    DOMAIN=$(prompt_domain "Domain (or press Enter to skip)")
    if [[ -n "$DOMAIN" ]]; then
        LE_EMAIL=$(prompt_safe "Email for SSL certificate (Let's Encrypt)" "")
    fi

    divider

    INSTALL_DIR=$(prompt_safe "Install directory" "$HOME/paperless-ag")
    DB_PASSWORD=$(generate_password)
    SECRET_KEY=$(generate_password)
    MCP_AUTH_TOKEN=$(generate_password)

    collect_local_ai_config
}

collect_addon_config() {
    echo "  We found Paperless-ngx running on this server."
    echo
    info "Container: $(docker inspect "$PAPERLESS_CONTAINER_ID" --format '{{.Name}}' 2>/dev/null | sed 's/^\///')"
    [[ -n "$PAPERLESS_COMPOSE_DIR" ]] && info "Compose dir: $PAPERLESS_COMPOSE_DIR"
    info "DB host: ${DETECTED_DB_HOST}"
    info "DB name: ${DETECTED_DB_NAME}"

    # Show credential detection status
    if [[ -n "$DETECTED_DB_PASS" ]]; then
        info "DB credentials: auto-detected"
    else
        warn "DB password: not found in config"
    fi

    if [[ -n "$DETECTED_ADMIN_USER" ]] && [[ -n "$DETECTED_ADMIN_PASS" ]]; then
        info "Paperless admin: auto-detected (${DETECTED_ADMIN_USER})"
    else
        warn "Paperless admin: not found in config -- need your credentials"
    fi

    divider

    echo "  We'll add semantic search to your existing Paperless installation."
    echo "  Your existing setup will not be modified (we use a docker-compose.override.yml)."
    echo

    if ! prompt_yn "Continue?"; then
        echo "  Cancelled."
        exit 0
    fi

    # ── Use auto-detected values, prompt only for what's missing ──

    # DB credentials
    DB_HOST="$DETECTED_DB_HOST"
    DB_NAME="$DETECTED_DB_NAME"
    DB_USER="$DETECTED_DB_USER"

    if [[ -n "$DETECTED_DB_PASS" ]]; then
        DB_PASS="$DETECTED_DB_PASS"
    else
        divider
        echo "  We couldn't find the database password automatically."
        echo "  Check your docker-compose.yml for POSTGRES_PASSWORD or PAPERLESS_DBPASS."
        echo
        DB_PASS=$(prompt_secret "Postgres password")
    fi

    # Paperless admin credentials
    if [[ -n "$DETECTED_ADMIN_USER" ]] && [[ -n "$DETECTED_ADMIN_PASS" ]]; then
        ADMIN_USER="$DETECTED_ADMIN_USER"
        ADMIN_PASSWORD="$DETECTED_ADMIN_PASS"
    else
        divider
        echo "  We need your Paperless admin credentials so the companion"
        echo "  container can access the Paperless API."
        echo
        ADMIN_USER=$(prompt_safe "Paperless admin username" "${DETECTED_ADMIN_USER:-admin}")
        ADMIN_PASSWORD=$(prompt_secret "Paperless admin password")
    fi

    # ── Validate credentials ─────────────────────────────────

    divider
    step "Validating credentials..."
    echo

    # Validate DB connection (retry loop)
    while ! validate_db_connection; do
        fail "Could not connect to Postgres (user=$DB_USER, db=$DB_NAME)"
        echo "  Check POSTGRES_PASSWORD in your docker-compose.yml."
        echo
        DB_PASS=$(prompt_secret "Postgres password")
    done
    info "Database connection verified"

    # Validate Paperless API (retry loop)
    while ! validate_paperless_api; do
        fail "Could not authenticate with Paperless (user=$ADMIN_USER)"
        echo "  Check your Paperless admin username and password."
        echo
        ADMIN_USER=$(prompt_safe "Paperless admin username" "$ADMIN_USER")
        ADMIN_PASSWORD=$(prompt_secret "Paperless admin password")
    done
    info "Paperless API authentication verified"

    divider

    echo "  Do you have a domain name pointed at this server?"
    echo -e "  ${DIM}(e.g., docs.smithfarms.com)${NC}"
    echo
    DOMAIN=$(prompt_domain "Domain (or press Enter to skip)")
    if [[ -n "$DOMAIN" ]]; then
        LE_EMAIL=$(prompt_safe "Email for SSL certificate (Let's Encrypt)" "")
    fi

    MCP_AUTH_TOKEN=$(generate_password)

    collect_local_ai_config
    if [[ "${LOCAL_AI_ENABLED:-false}" == "true" && -z "${DOMAIN:-}" && -n "${OPEN_WEBUI_FALLBACK_URL:-}" ]]; then
        # Add-on installs without a domain do not add a new Caddy front door,
        # so the direct host-port URL is the reliable Open WebUI URL.
        OPEN_WEBUI_URL="$OPEN_WEBUI_FALLBACK_URL"
    fi
}

# ── Fresh Install ────────────────────────────────────────

do_fresh_install() {
    local install_dir="$INSTALL_DIR"

    # Check for existing installation
    if [[ -d "$install_dir" ]] && [[ -f "$install_dir/docker-compose.yml" ]]; then
        echo
        warn "Existing installation found at $install_dir"
        echo
        echo "    1) Update to latest version"
        echo "    2) Cancel"
        echo
        local choice
        choice=$(prompt "Choose" "1")
        case "$choice" in
            1)
                step "Updating existing installation..."
                if [[ -f "$install_dir/update.sh" ]]; then
                    bash "$install_dir/update.sh"
                    return
                else
                    warn "No update.sh found. Re-running full install."
                fi
                ;;
            *) exit 0 ;;
        esac
    fi

    divider
    echo -e "  ${BOLD}Setting things up. This may take a few minutes...${NC}"
    echo

    # Determine Caddy ports
    local caddy_ports='      - "80:80"'
    if [[ -n "${DOMAIN:-}" ]]; then
        caddy_ports="$caddy_ports"$'\n''      - "443:443"'
    fi

    # Create directory
    mkdir -p "$install_dir/backups"
    info "Created $install_dir"

    # Determine Paperless URL for PAPERLESS_URL env var
    local paperless_url
    if [[ -n "${DOMAIN:-}" ]]; then
        paperless_url="https://$DOMAIN"
    else
        local detected_ip
        detected_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
        if [[ -n "$detected_ip" ]]; then
            paperless_url="http://${detected_ip}"
        else
            paperless_url="http://localhost"
            warn "Could not detect server IP. Update PAPERLESS_URL in .env if needed."
        fi
    fi

    local tool_server_connections
    tool_server_connections=$(build_tool_server_connections_json "$MCP_AUTH_TOKEN")

    local local_ai_services=""
    local local_ai_volumes=""
    local local_ai_caddy_depends=""
    if [[ "${LOCAL_AI_ENABLED:-false}" == "true" ]]; then
        local_ai_caddy_depends=$'\n      - open-webui'
        local_ai_volumes=$'\n  ollama:\n  open-webui:'
        local_ai_services="
  ollama:
    image: ${OLLAMA_IMAGE}
    restart: unless-stopped
    volumes:
      - ollama:/root/.ollama

  open-webui:
    image: ${OPEN_WEBUI_IMAGE}
    restart: unless-stopped
    depends_on:
      - ollama
      - companion
    ports:
      - \"\${OPEN_WEBUI_PORT_MAPPING}\"
    environment:
      OLLAMA_BASE_URL: http://ollama:11434
      WEBUI_SECRET_KEY: \${WEBUI_SECRET_KEY}
      WEBUI_AUTH: \"True\"
      ENABLE_DIRECT_CONNECTIONS: \"True\"
      BYPASS_ADMIN_ACCESS_CONTROL: \"True\"
      DEFAULT_MODELS: \"\${OLLAMA_DEFAULT_MODEL}\"
      DEFAULT_MODEL_PARAMS: '\${OPEN_WEBUI_DEFAULT_MODEL_PARAMS}'
      WEBUI_URL: \${OPEN_WEBUI_URL}
      TOOL_SERVER_CONNECTIONS: >-
        ${tool_server_connections}
    volumes:
      - open-webui:/app/backend/data
"
    fi

    # Generate docker-compose.yml
    cat > "$install_dir/docker-compose.yml" <<COMPOSE
services:
  db:
    image: pgvector/pgvector:pg16
    restart: unless-stopped
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: paperless
      POSTGRES_USER: paperless
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U paperless"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  paperless:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - paperless-data:/usr/src/paperless/data
      - paperless-media:/usr/src/paperless/media
      - paperless-export:/usr/src/paperless/export
      - paperless-consume:/usr/src/paperless/consume
    environment:
      PAPERLESS_REDIS: redis://redis:6379
      PAPERLESS_DBHOST: db
      PAPERLESS_DBNAME: paperless
      PAPERLESS_DBUSER: paperless
      PAPERLESS_DBPASS: \${DB_PASSWORD}
      PAPERLESS_SECRET_KEY: \${SECRET_KEY}
      PAPERLESS_TIME_ZONE: \${TIMEZONE}
      PAPERLESS_URL: \${PAPERLESS_URL}
      PAPERLESS_ADMIN_USER: \${ADMIN_USER}
      PAPERLESS_ADMIN_PASSWORD: \${ADMIN_PASSWORD}
    healthcheck:
      test: ["CMD", "curl", "-fs", "http://localhost:8000"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 90s

  companion:
    image: ${COMPANION_IMAGE}
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
      paperless:
        condition: service_healthy
    environment:
      PAPERLESS_API_URL: http://paperless:8000
      PAPERLESS_USERNAME: \${ADMIN_USER}
      PAPERLESS_PASSWORD: \${ADMIN_PASSWORD}
      # DB_PASSWORD is generated from base64 with /+= stripped, so only [A-Za-z0-9] — safe to embed without URL-encoding.
      DATABASE_URL: postgresql://paperless:\${DB_PASSWORD}@db:5432/paperless
      EMBEDDING_MODEL: all-MiniLM-L6-v2
      SYNC_INTERVAL_SECONDS: "60"
      MCP_HTTP_PORT: "3001"
      MCP_AUTH_TOKEN: \${MCP_AUTH_TOKEN}
      PYTHONUNBUFFERED: "1"
${local_ai_services}

  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    ports:
${caddy_ports}
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy-data:/data
      - caddy-config:/config
    depends_on:
      - paperless
      - companion
${local_ai_caddy_depends}

volumes:
  pgdata:
  redisdata:
  paperless-data:
  paperless-media:
  paperless-export:
  paperless-consume:
  caddy-data:
  caddy-config:
${local_ai_volumes}
COMPOSE
    info "Generated docker-compose.yml"

    # Generate .env
    cat > "$install_dir/.env" <<ENV
# Paperless Ag configuration -- generated by installer
# Do not share this file. It contains passwords.

ADMIN_USER='${ADMIN_USER}'
ADMIN_PASSWORD='${ADMIN_PASSWORD}'
DB_PASSWORD='${DB_PASSWORD}'
SECRET_KEY='${SECRET_KEY}'
TIMEZONE='${TIMEZONE}'
PAPERLESS_URL='${paperless_url}'
MCP_AUTH_TOKEN='${MCP_AUTH_TOKEN}'
LOCAL_AI_ENABLED='${LOCAL_AI_ENABLED:-false}'
LOCAL_AI_HTTP_EXPOSE='${LOCAL_AI_HTTP_EXPOSE:-false}'
AI_DOMAIN='${AI_DOMAIN:-}'
WEBUI_SECRET_KEY='${WEBUI_SECRET_KEY:-}'
OPEN_WEBUI_HOST_PORT='${OPEN_WEBUI_HOST_PORT:-}'
OPEN_WEBUI_HOST_BIND='${OPEN_WEBUI_HOST_BIND:-}'
OPEN_WEBUI_PORT_MAPPING='${OPEN_WEBUI_PORT_MAPPING:-}'
OPEN_WEBUI_URL='${OPEN_WEBUI_URL:-}'
OPEN_WEBUI_FALLBACK_URL='${OPEN_WEBUI_FALLBACK_URL:-}'
OLLAMA_DEFAULT_MODEL='${OLLAMA_DEFAULT_MODEL:-}'
OLLAMA_PULL_MODEL_ON_INSTALL='${OLLAMA_PULL_MODEL_ON_INSTALL:-false}'
OPEN_WEBUI_DEFAULT_MODEL_PARAMS='${OPEN_WEBUI_DEFAULT_MODEL_PARAMS:-}'
ENV
    chmod 600 "$install_dir/.env"
    info "Generated .env"

    # Generate Caddyfile
    generate_caddyfile "$install_dir/Caddyfile"
    info "Generated Caddyfile"

    # Generate helper scripts
    generate_update_script "$install_dir"
    generate_backup_script "$install_dir"
    generate_restore_script "$install_dir"
    info "Generated helper scripts (update.sh, backup.sh, restore.sh)"

    # Pull images and start
    step "Pulling container images (this is the slow part)..."
    (cd "$install_dir" && run_quiet docker compose pull)
    info "Images pulled"

    step "Starting services..."
    (cd "$install_dir" && run_quiet docker compose up -d)
    info "Services started"

    step "Waiting for Paperless to be ready (this can take a minute on first run)..."
    local attempts=0
    while (( attempts < 60 )); do
        if (cd "$install_dir" && docker compose exec -T paperless curl -fs http://localhost:8000 &>/dev/null); then
            break
        fi
        sleep 5
        (( attempts++ ))
    done
    if (( attempts >= 60 )); then
        warn "Paperless is taking longer than expected to start."
        warn "Check logs with: cd $install_dir && docker compose logs paperless"
    else
        info "Paperless is ready"
    fi

    # Wait briefly for companion to connect
    sleep 5
    if (cd "$install_dir" && docker compose ps companion 2>/dev/null | grep -q "running"); then
        info "Companion service connected"
    else
        warn "Companion service may still be starting. Check: docker compose logs companion"
    fi

    if [[ "${LOCAL_AI_ENABLED:-false}" == "true" ]]; then
        if (cd "$install_dir" && docker compose ps open-webui 2>/dev/null | grep -q "running"); then
            info "Open WebUI is running"
        else
            warn "Open WebUI may still be starting. Check: docker compose logs open-webui"
        fi

        if [[ "${OLLAMA_PULL_MODEL_ON_INSTALL:-false}" == "true" && -n "${OLLAMA_DEFAULT_MODEL:-}" ]]; then
            step "Downloading Ollama model ${OLLAMA_DEFAULT_MODEL}..."
            if (cd "$install_dir" && docker compose exec -T ollama ollama pull "$OLLAMA_DEFAULT_MODEL"); then
                info "Ollama model downloaded"
            else
                warn "Model download failed or was interrupted. Open WebUI can pull it later."
            fi
        fi
    fi

    # Set up daily backup cron
    setup_backup_cron "$install_dir"

    # Print summary
    print_fresh_summary "$install_dir" "$paperless_url"
}

# ── Add-on Install ───────────────────────────────────────

do_addon_install() {
    local compose_dir="$PAPERLESS_COMPOSE_DIR"

    if [[ -z "$compose_dir" ]] || [[ ! -d "$compose_dir" ]]; then
        compose_dir=$(prompt_required "Path to your Paperless docker-compose.yml directory")
    fi

    if [[ ! -f "$compose_dir/docker-compose.yml" ]]; then
        fail "No docker-compose.yml found in $compose_dir"
        exit 1
    fi

    # Check for existing override
    if [[ -f "$compose_dir/docker-compose.override.yml" ]]; then
        if grep -q "paperless-ag\|companion" "$compose_dir/docker-compose.override.yml" 2>/dev/null; then
            warn "Paperless Ag appears to already be installed (found override file)."
            if ! prompt_yn "Overwrite the existing override?" "n"; then
                exit 0
            fi
            cp "$compose_dir/docker-compose.override.yml" "$compose_dir/docker-compose.override.yml.bak.$(date +%s)"
            info "Backed up existing override file"
        else
            warn "A docker-compose.override.yml already exists in $compose_dir"
            warn "We need to add to it. A backup will be created."
            cp "$compose_dir/docker-compose.override.yml" "$compose_dir/docker-compose.override.yml.bak.$(date +%s)"
            info "Backed up existing override file"
        fi
    fi

    divider
    echo -e "  ${BOLD}Setting things up...${NC}"
    echo

    # Check pgvector
    if detect_pgvector; then
        info "pgvector is available in your Postgres"
    else
        if [[ -z "${DB_PG_MAJOR:-}" ]]; then
            fail "Could not determine Postgres major version from image: ${DB_IMAGE:-unknown}"
            fail "Cannot install pgvector automatically."
            echo "  Install pgvector manually or switch to a pgvector/pgvector image."
            exit 1
        fi

        if ! validate_pgvector_image; then
            fail "No pgvector image found for Postgres ${DB_PG_MAJOR}"
            fail "pgvector/pgvector:pg${DB_PG_MAJOR} does not exist."
            echo "  Check https://hub.docker.com/r/pgvector/pgvector/tags for available versions."
            exit 1
        fi

        warn "Your Postgres doesn't have pgvector."
        if [[ -n "${DB_IMAGE:-}" ]]; then
            echo "  Current image: $DB_IMAGE"
        fi
        echo "  Replacement:   $PGVECTOR_IMAGE"
        echo
        echo "  We'll override the Postgres image to $PGVECTOR_IMAGE"
        echo "  (drop-in replacement -- your data stays intact)."
        echo
        if ! prompt_yn "Continue?"; then
            exit 0
        fi
        NEEDS_PGVECTOR_OVERRIDE=true
    fi

    # Pull companion image
    step "Pulling Paperless Ag companion image..."
    run_quiet docker pull "$COMPANION_IMAGE"
    info "Companion image pulled"
    if [[ "${LOCAL_AI_ENABLED:-false}" == "true" ]]; then
        step "Pulling Local AI images..."
        run_quiet docker pull "$OLLAMA_IMAGE"
        run_quiet docker pull "$OPEN_WEBUI_IMAGE"
        info "Local AI images pulled"
    fi

    # Determine internal Paperless URL
    local paperless_internal_url="http://${PAPERLESS_SERVICE_NAME}:8000"
    local tool_server_connections
    tool_server_connections=$(build_tool_server_connections_json "$MCP_AUTH_TOKEN")

    # Generate docker-compose.override.yml
    local caddy_depends="      - companion"
    if [[ "${LOCAL_AI_ENABLED:-false}" == "true" ]]; then
        caddy_depends+=$'\n      - open-webui'
    fi

    local override_content="# Paperless Ag add-on -- generated by installer
# This file is automatically loaded by docker compose.
services:"

    # Add pgvector override if needed
    if [[ "${NEEDS_PGVECTOR_OVERRIDE:-}" == "true" ]]; then
        override_content+="
  ${DB_HOST}:
    image: ${PGVECTOR_IMAGE}"
    fi

    override_content+="
  companion:
    image: ${COMPANION_IMAGE}
    restart: unless-stopped
    depends_on:
      - ${DB_HOST}
    env_file:
      - paperless-ag.env"

    # Write companion env to a separate file (avoids YAML escaping issues)
    cat > "$compose_dir/paperless-ag.env" <<ENVFILE
PAPERLESS_API_URL='${paperless_internal_url}'
PAPERLESS_USERNAME='${ADMIN_USER}'
PAPERLESS_PASSWORD='${ADMIN_PASSWORD}'
DB_HOST='${DB_HOST}'
DB_PORT='5432'
DB_NAME='${DB_NAME}'
DB_USER='${DB_USER}'
DB_PASS='${DB_PASS}'
EMBEDDING_MODEL='all-MiniLM-L6-v2'
SYNC_INTERVAL_SECONDS='60'
MCP_HTTP_PORT='3001'
MCP_AUTH_TOKEN='${MCP_AUTH_TOKEN}'
PYTHONUNBUFFERED='1'
LOCAL_AI_ENABLED='${LOCAL_AI_ENABLED:-false}'
LOCAL_AI_HTTP_EXPOSE='${LOCAL_AI_HTTP_EXPOSE:-false}'
AI_DOMAIN='${AI_DOMAIN:-}'
WEBUI_SECRET_KEY='${WEBUI_SECRET_KEY:-}'
OPEN_WEBUI_HOST_PORT='${OPEN_WEBUI_HOST_PORT:-}'
OPEN_WEBUI_HOST_BIND='${OPEN_WEBUI_HOST_BIND:-}'
OPEN_WEBUI_PORT_MAPPING='${OPEN_WEBUI_PORT_MAPPING:-}'
OPEN_WEBUI_URL='${OPEN_WEBUI_URL:-}'
OPEN_WEBUI_FALLBACK_URL='${OPEN_WEBUI_FALLBACK_URL:-}'
OLLAMA_DEFAULT_MODEL='${OLLAMA_DEFAULT_MODEL:-}'
OLLAMA_PULL_MODEL_ON_INSTALL='${OLLAMA_PULL_MODEL_ON_INSTALL:-false}'
OPEN_WEBUI_DEFAULT_MODEL_PARAMS='${OPEN_WEBUI_DEFAULT_MODEL_PARAMS:-}'
ENVFILE
    chmod 600 "$compose_dir/paperless-ag.env"

    # Expose MCP port directly when no domain/Caddy is configured
    if [[ -z "${DOMAIN:-}" ]]; then
        override_content+="
    ports:
      - \"3001:3001\""
    fi

    if [[ "${LOCAL_AI_ENABLED:-false}" == "true" ]]; then
        override_content+="

  ollama:
    image: ${OLLAMA_IMAGE}
    restart: unless-stopped
    volumes:
      - ollama:/root/.ollama

  open-webui:
    image: ${OPEN_WEBUI_IMAGE}
    restart: unless-stopped
    depends_on:
      - ollama
      - companion
    env_file:
      - paperless-ag.env
    ports:
      - \"${OPEN_WEBUI_PORT_MAPPING}\"
    environment:
      OLLAMA_BASE_URL: http://ollama:11434
      WEBUI_AUTH: \"True\"
      ENABLE_DIRECT_CONNECTIONS: \"True\"
      BYPASS_ADMIN_ACCESS_CONTROL: \"True\"
      DEFAULT_MODELS: \"${OLLAMA_DEFAULT_MODEL}\"
      DEFAULT_MODEL_PARAMS: '${OPEN_WEBUI_DEFAULT_MODEL_PARAMS:-}'
      TOOL_SERVER_CONNECTIONS: >-
        ${tool_server_connections}
    volumes:
      - open-webui:/app/backend/data"
    fi

    # Add Caddy if domain provided
    if [[ -n "${DOMAIN:-}" ]]; then
        override_content+="

  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    ports:
      - \"80:80\"
      - \"443:443\"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy-data:/data
      - caddy-config:/config
    depends_on:
${caddy_depends}

volumes:
  caddy-data:
  caddy-config:"
        if [[ "${LOCAL_AI_ENABLED:-false}" == "true" ]]; then
            override_content+="
  ollama:
  open-webui:"
        fi
    elif [[ "${LOCAL_AI_ENABLED:-false}" == "true" ]]; then
        override_content+="

volumes:
  ollama:
  open-webui:"
    fi

    echo "$override_content" > "$compose_dir/docker-compose.override.yml"
    info "Generated docker-compose.override.yml"

    # Generate Caddyfile if domain provided
    if [[ -n "${DOMAIN:-}" ]]; then
        generate_caddyfile "$compose_dir/Caddyfile"
        info "Generated Caddyfile"
    fi

    # Generate helper scripts
    generate_addon_update_script "$compose_dir"
    info "Generated update script"

    # Restart the stack (picks up override automatically)
    step "Restarting services..."
    (cd "$compose_dir" && run_quiet docker compose up -d)
    info "Services started"

    # Wait for companion
    sleep 10
    if (cd "$compose_dir" && docker compose ps companion 2>/dev/null | grep -q "running"); then
        info "Companion service is running"
    else
        warn "Companion may still be starting. Check: cd $compose_dir && docker compose logs companion"
    fi

    if [[ "${LOCAL_AI_ENABLED:-false}" == "true" ]]; then
        if (cd "$compose_dir" && docker compose ps open-webui 2>/dev/null | grep -q "running"); then
            info "Open WebUI is running"
        else
            warn "Open WebUI may still be starting. Check: cd $compose_dir && docker compose logs open-webui"
        fi

        if [[ "${OLLAMA_PULL_MODEL_ON_INSTALL:-false}" == "true" && -n "${OLLAMA_DEFAULT_MODEL:-}" ]]; then
            step "Downloading Ollama model ${OLLAMA_DEFAULT_MODEL}..."
            if (cd "$compose_dir" && docker compose exec -T ollama ollama pull "$OLLAMA_DEFAULT_MODEL"); then
                info "Ollama model downloaded"
            else
                warn "Model download failed or was interrupted. Open WebUI can pull it later."
            fi
        fi
    fi

    # Print summary
    print_addon_summary "$compose_dir"
}

# ── File Generators ──────────────────────────────────────

generate_caddyfile() {
    local filepath="$1"
    local paperless_service="${PAPERLESS_SERVICE_NAME:-paperless}"
    local ai_domain_block=""
    local ai_lan_block=""

    if [[ "${LOCAL_AI_ENABLED:-false}" == "true" && -n "${AI_DOMAIN:-}" ]]; then
        local ai_tls_block=""
        if [[ -n "${LE_EMAIL:-}" ]]; then
            ai_tls_block=$'\n    tls '"$LE_EMAIL"
        fi
        ai_domain_block="${AI_DOMAIN} {${ai_tls_block}
    reverse_proxy open-webui:8080
}

"
    elif [[ "${LOCAL_AI_ENABLED:-false}" == "true" && "${LOCAL_AI_HTTP_EXPOSE:-false}" == "true" ]]; then
        ai_lan_block="http://ai.*.sslip.io {
    reverse_proxy open-webui:8080
}

"
    fi

    if [[ -n "${DOMAIN:-}" ]]; then
        local tls_block=""
        if [[ -n "${LE_EMAIL:-}" ]]; then
            tls_block=$'\n    tls '"$LE_EMAIL"
        fi
        cat > "$filepath" <<CADDY
${ai_domain_block}${ai_lan_block}
${DOMAIN} {${tls_block}
    @discovery path /.well-known/oauth-authorization-server /.well-known/openid-configuration
    handle @discovery {
        respond 404
    }
    @mcp path /mcp /mcp/*
    handle @mcp {
        reverse_proxy companion:3001 {
            header_up Host localhost:3001
        }
    }
    handle {
        reverse_proxy ${paperless_service}:8000
    }
}
CADDY
    else
        cat > "$filepath" <<CADDY
${ai_domain_block}${ai_lan_block}
:80 {
    @discovery path /.well-known/oauth-authorization-server /.well-known/openid-configuration
    handle @discovery {
        respond 404
    }
    @mcp path /mcp /mcp/*
    handle @mcp {
        reverse_proxy companion:3001 {
            header_up Host localhost:3001
        }
    }
    handle {
        reverse_proxy ${paperless_service}:8000
    }
}
CADDY
    fi
}

generate_update_script() {
    local install_dir="$1"
    cat > "$install_dir/update.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p backups

if docker compose ps --status running db 2>/dev/null | grep -q db; then
    echo "Backing up database before update..."
    docker compose exec -T db pg_dump --clean -U paperless paperless > "backups/pre-update-$(date +%Y%m%d-%H%M%S).sql"
    echo "[✓] Database backed up"
else
    echo "[!] Database not running — skipping backup"
fi

# Migrate Caddyfile if needed (handle_path -> handle with named matcher, add @discovery matcher for OAuth/OIDC endpoints)
if [[ -f Caddyfile ]] && grep -q 'handle_path /mcp' Caddyfile; then
    echo "Updating Caddyfile for streamable HTTP transport..."
    sed -i 's|handle_path /mcp/\* {|@mcp path /mcp /mcp/*\n    handle @mcp {|' Caddyfile
    # Add discovery block if missing and no legacy oauth block needs migration
    if ! grep -q 'openid-configuration' Caddyfile \
        && ! grep -q '@discovery path' Caddyfile \
        && ! grep -q 'handle /\.well-known/oauth\*' Caddyfile; then
        sed -i '/@mcp path/i\    @discovery path \/.well-known\/oauth-authorization-server \/.well-known\/openid-configuration\n    handle @discovery {\n        respond 404\n    }' Caddyfile
    fi
    echo "[✓] Caddyfile updated"
fi
# Migrate legacy .well-known/oauth* to specific discovery endpoints
if [[ -f Caddyfile ]] && grep -q 'handle /\.well-known/oauth\*' Caddyfile; then
    sed -i '/handle \/\.well-known\/oauth\*/,/}/c\    @discovery path \/.well-known\/oauth-authorization-server \/.well-known\/openid-configuration\n    handle @discovery {\n        respond 404\n    }' Caddyfile
    echo "[✓] Caddyfile discovery block updated"
fi

echo "Pulling latest images..."
docker compose pull

echo "Restarting services..."
docker compose up -d

echo ""
echo "[✓] Update complete. Check your Paperless UI to confirm."
SCRIPT
    chmod +x "$install_dir/update.sh"
}

generate_addon_update_script() {
    local compose_dir="$1"
    cat > "$compose_dir/paperless-ag-update.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "Pulling latest Paperless Ag image..."
docker pull ghcr.io/nerdoutinc/paperless-ag:latest

echo "Restarting services..."
docker compose up -d

echo ""
echo "[✓] Paperless Ag updated."
SCRIPT
    chmod +x "$compose_dir/paperless-ag-update.sh"
}

generate_backup_script() {
    local install_dir="$1"
    cat > "$install_dir/backup.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/paperless-$TIMESTAMP.sql"

mkdir -p "$BACKUP_DIR"
echo "Backing up database..."
docker compose exec -T db pg_dump --clean -U paperless paperless > "$BACKUP_FILE"
echo "[✓] Backup saved to $BACKUP_FILE"

# Keep only the last 7 daily backups
ls -t "$BACKUP_DIR"/paperless-*.sql 2>/dev/null | tail -n +8 | xargs -r rm
echo "[✓] Old backups cleaned up (keeping last 7)"
SCRIPT
    chmod +x "$install_dir/backup.sh"
}

generate_restore_script() {
    local install_dir="$1"
    cat > "$install_dir/restore.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ $# -lt 1 ]]; then
    echo "Usage: bash restore.sh <backup-file.sql>"
    echo ""
    echo "Available backups:"
    ls -lh backups/*.sql 2>/dev/null || echo "  (none found)"
    exit 1
fi

BACKUP_FILE="$1"
if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Error: File not found: $BACKUP_FILE"
    exit 1
fi

echo "WARNING: This will replace your current database with the backup."
read -rp "Are you sure? [y/N]: " confirm
if [[ "${confirm,,}" != "y" ]]; then
    echo "Cancelled."
    exit 0
fi

echo "Stopping Paperless and companion..."
docker compose stop paperless companion

echo "Restoring database from $BACKUP_FILE..."
docker compose exec -T db psql -U paperless -d paperless < "$BACKUP_FILE"

echo "Restarting services..."
docker compose up -d

echo ""
echo "[✓] Database restored. Paperless is restarting."
SCRIPT
    chmod +x "$install_dir/restore.sh"
}

setup_backup_cron() {
    local install_dir="$1"
    if ! command -v crontab &>/dev/null; then
        warn "crontab not found. Install cron to enable daily backups."
        return 0
    fi
    # Add daily backup cron job (2 AM) if not already present
    local cron_line="0 2 * * * cd \"$install_dir\" && bash backup.sh >> \"$install_dir/backups/cron.log\" 2>&1"
    if ! crontab -l 2>/dev/null | grep -Fq "$cron_line" 2>/dev/null; then
        if { crontab -l 2>/dev/null || true; echo "$cron_line"; } | crontab - 2>/dev/null; then
            info "Daily backup scheduled (2:00 AM)"
        else
            warn "Could not set up cron job. Run manually: cd \"$install_dir\" && bash backup.sh"
        fi
    fi
}

# ── Summary Output ───────────────────────────────────────

print_fresh_summary() {
    local install_dir="$1"
    local paperless_url="$2"
    local mcp_url="${paperless_url}/mcp"

    echo
    echo -e "${BOLD}════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  All done!${NC}"
    echo -e "${BOLD}════════════════════════════════════════════════════${NC}"
    echo
    echo -e "  ${BOLD}Paperless Web UI:${NC}  $paperless_url"
    echo -e "  ${BOLD}Username:${NC}          $ADMIN_USER"
    echo -e "  ${BOLD}Password:${NC}          (what you entered)"
    echo
    echo "  Upload documents: Drag and drop in the web UI, or email them"
    echo "                    (configure in Settings > Mail)"
    echo
    if [[ "${LOCAL_AI_ENABLED:-false}" == "true" ]]; then
        echo -e "  ${BOLD}LOCAL AI CHAT:${NC}"
        echo "  Open WebUI:        ${OPEN_WEBUI_URL}"
        if [[ -n "${OPEN_WEBUI_FALLBACK_URL:-}" && "${OPEN_WEBUI_FALLBACK_URL}" != "${OPEN_WEBUI_URL}" ]]; then
            echo "  Fallback URL:      ${OPEN_WEBUI_FALLBACK_URL}"
        fi
        if [[ -n "${OLLAMA_DEFAULT_MODEL:-}" ]]; then
            echo "  Ollama model:      ${OLLAMA_DEFAULT_MODEL}"
            if [[ "${OPEN_WEBUI_DEFAULT_MODEL_PARAMS:-}" == *'"think":false'* ]]; then
                echo "  Ollama thinking:   disabled by default in Open WebUI"
            fi
        else
            echo "  Ollama model:      choose/pull one in Open WebUI"
        fi
        echo "  Paperless Ag MCP:  preconfigured in Open WebUI"
        echo
    fi
    echo -e "  ${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "  ${BOLD}CONNECT TO CLAUDE:${NC}"
    echo
    echo "  In Claude Code, run this command:"
    echo
    echo -e "    ${BOLD}claude mcp add --transport http paperless-ag ${mcp_url} \\\\${NC}"
    echo -e "    ${BOLD}  --header \"Authorization: Bearer ${MCP_AUTH_TOKEN}\"${NC}"
    echo
    echo "  Or add this to your .mcp.json:"
    echo
    echo "    {"
    echo "      \"mcpServers\": {"
    echo "        \"paperless-ag\": {"
    echo "          \"type\": \"http\","
    echo "          \"url\": \"${mcp_url}\","
    echo "          \"headers\": {"
    echo "            \"Authorization\": \"Bearer ${MCP_AUTH_TOKEN}\""
    echo "          }"
    echo "        }"
    echo "      }"
    echo "    }"
    echo
    echo "  Claude Desktop (mcp-remote):"
    echo
    echo "    {"
    echo "      \"mcpServers\": {"
    echo "        \"paperless-ag\": {"
    echo "          \"command\": \"npx\","
    echo "          \"args\": ["
    echo "            \"-y\", \"mcp-remote\", \"${mcp_url}\","
    echo "            \"--allow-http\","
    echo "            \"--header\", \"Authorization:Bearer ${MCP_AUTH_TOKEN}\""
    echo "          ]"
    echo "        }"
    echo "      }"
    echo "    }"
    echo
    if [[ "${LOCAL_AI_ENABLED:-false}" == "true" ]]; then
        echo "  Open WebUI MCP seed/import JSON:"
        echo
        echo "    $(build_tool_server_connections_json "$MCP_AUTH_TOKEN")"
        echo
    fi
    echo "  Claude Desktop uses mcp-remote instead of the .mcp.json HTTP block."
    echo "  Open Claude > Settings > Developer > Edit Config and use:"
    echo "    Server URL: ${mcp_url}"
    echo "    Token:      ${MCP_AUTH_TOKEN}"
    echo "  Full config example: https://paperless.fullstack.ag"
    echo
    echo "  Then ask Claude: \"Search my farm documents for crop insurance\""
    echo
    echo -e "  ${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo "  To stop:    cd $install_dir && docker compose down"
    echo "  To start:   cd $install_dir && docker compose up -d"
    echo "  To update:  bash $install_dir/update.sh"
    echo "  To backup:  bash $install_dir/backup.sh"
    echo "  Logs:       cd $install_dir && docker compose logs -f"
    echo
    echo "  Need help?  https://github.com/NerdOutInc/paperless-ag/issues"
    echo
}

print_addon_summary() {
    local compose_dir="$1"
    local ip_addr
    ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR_SERVER_IP")

    local mcp_url
    if [[ -n "${DOMAIN:-}" ]]; then
        mcp_url="https://${DOMAIN}/mcp"
    else
        mcp_url="http://${ip_addr}:3001/mcp"
    fi

    echo
    echo -e "${BOLD}════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  Paperless Ag installed!${NC}"
    echo -e "${BOLD}════════════════════════════════════════════════════${NC}"
    echo
    echo "  Semantic search is now active. Your existing Paperless"
    echo "  documents will be embedded automatically (check logs)."
    echo
    if [[ "${LOCAL_AI_ENABLED:-false}" == "true" ]]; then
        echo -e "  ${BOLD}LOCAL AI CHAT:${NC}"
        echo "  Open WebUI:        ${OPEN_WEBUI_URL}"
        if [[ -n "${OPEN_WEBUI_FALLBACK_URL:-}" && "${OPEN_WEBUI_FALLBACK_URL}" != "${OPEN_WEBUI_URL}" ]]; then
            echo "  Fallback URL:      ${OPEN_WEBUI_FALLBACK_URL}"
        fi
        if [[ -n "${OLLAMA_DEFAULT_MODEL:-}" ]]; then
            echo "  Ollama model:      ${OLLAMA_DEFAULT_MODEL}"
            if [[ "${OPEN_WEBUI_DEFAULT_MODEL_PARAMS:-}" == *'"think":false'* ]]; then
                echo "  Ollama thinking:   disabled by default in Open WebUI"
            fi
        else
            echo "  Ollama model:      choose/pull one in Open WebUI"
        fi
        echo "  Paperless Ag MCP:  preconfigured in Open WebUI"
        echo
    fi
    echo -e "  ${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "  ${BOLD}CONNECT TO CLAUDE:${NC}"
    echo
    echo "  In Claude Code, run this command:"
    echo
    echo -e "    ${BOLD}claude mcp add --transport http paperless-ag ${mcp_url} \\\\${NC}"
    echo -e "    ${BOLD}  --header \"Authorization: Bearer ${MCP_AUTH_TOKEN}\"${NC}"
    echo
    echo "  Or add this to your .mcp.json:"
    echo
    echo "    {"
    echo "      \"mcpServers\": {"
    echo "        \"paperless-ag\": {"
    echo "          \"type\": \"http\","
    echo "          \"url\": \"${mcp_url}\","
    echo "          \"headers\": {"
    echo "            \"Authorization\": \"Bearer ${MCP_AUTH_TOKEN}\""
    echo "          }"
    echo "        }"
    echo "      }"
    echo "    }"
    echo
    echo "  Claude Desktop (mcp-remote):"
    echo
    echo "    {"
    echo "      \"mcpServers\": {"
    echo "        \"paperless-ag\": {"
    echo "          \"command\": \"npx\","
    echo "          \"args\": ["
    echo "            \"-y\", \"mcp-remote\", \"${mcp_url}\","
    echo "            \"--allow-http\","
    echo "            \"--header\", \"Authorization:Bearer ${MCP_AUTH_TOKEN}\""
    echo "          ]"
    echo "        }"
    echo "      }"
    echo "    }"
    echo
    if [[ "${LOCAL_AI_ENABLED:-false}" == "true" ]]; then
        echo "  Open WebUI MCP seed/import JSON:"
        echo
        echo "    $(build_tool_server_connections_json "$MCP_AUTH_TOKEN")"
        echo
    fi
    echo "  Claude Desktop uses mcp-remote instead of the .mcp.json HTTP block."
    echo "  Open Claude > Settings > Developer > Edit Config and use:"
    echo "    Server URL: ${mcp_url}"
    echo "    Token:      ${MCP_AUTH_TOKEN}"
    echo "  Full config example: https://paperless.fullstack.ag"
    echo
    echo "  Then ask Claude: \"Search my farm documents for crop insurance\""
    echo
    echo -e "  ${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo "  Companion logs: cd $compose_dir && docker compose logs -f companion"
    echo "  Update:         bash $compose_dir/paperless-ag-update.sh"
    echo
    echo "  Need help?  https://github.com/NerdOutInc/paperless-ag/issues"
    echo
}

# ── Main ─────────────────────────────────────────────────

main() {
    banner

    # Ensure we have a TTY for interactive prompts (e.g., curl | bash)
    if ! : </dev/tty 2>/dev/null; then
        fail "No TTY available. This installer requires interactive input." >&2
        echo "  Re-run with: ssh -t host 'curl -fsSL ... | bash'" >&2
        exit 1
    fi

    echo "  Checking your system..."
    echo
    check_platform
    check_docker
    check_resources
    check_ports

    divider

    # Detect existing Paperless-ngx
    PAPERLESS_CONTAINER_ID=""
    PAPERLESS_COMPOSE_DIR=""
    PAPERLESS_COMPOSE_PROJECT=""
    PAPERLESS_SERVICE_NAME="paperless"
    NEEDS_PGVECTOR_OVERRIDE=""

    if detect_paperless; then
        # Detect DB container and pgvector early so validation works
        detect_pgvector || true

        echo "  How would you like to install Paperless Ag?"
        echo
        echo "    1) Add to my existing Paperless-ngx (recommended)"
        echo "    2) Fresh install (new Paperless + companion)"
        echo
        local choice
        choice=$(prompt "Choose" "1")
        case "$choice" in
            1)
                collect_addon_config
                do_addon_install
                ;;
            *)
                collect_fresh_config
                do_fresh_install
                ;;
        esac
    else
        echo "  No existing Paperless-ngx found. Setting up a fresh install."
        divider
        collect_fresh_config
        do_fresh_install
    fi
}

main "$@"
