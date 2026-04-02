#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# Paperless Ag Installer
# https://github.com/NerdOutInc/paperless-ag
#
# Usage: curl -fsSL https://paperless.fullstack.ag/install.sh | bash
# ─────────────────────────────────────────────────────────

COMPANION_IMAGE="ghcr.io/nerdoutinc/paperless-ag:latest"
MIN_DISK_GB=5
MIN_RAM_MB=2048
RECOMMENDED_RAM_MB=4096

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
    echo -e "${DIM}  Semantic search for Paperless NGX${NC}"
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
    total_ram_mb=$(free -m 2>/dev/null | awk '/Mem:/ {print $2}' || echo "0")
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

    # Extract DB connection from container environment
    local env_output
    env_output=$(docker inspect "$container_id" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null || echo "")

    DETECTED_DB_HOST=$(echo "$env_output" | grep "^PAPERLESS_DBHOST=" | cut -d= -f2- || echo "")
    DETECTED_DB_NAME=$(echo "$env_output" | grep "^PAPERLESS_DBNAME=" | cut -d= -f2- || echo "")
    DETECTED_DB_USER=$(echo "$env_output" | grep "^PAPERLESS_DBUSER=" | cut -d= -f2- || echo "")
    DETECTED_DB_PASS=$(echo "$env_output" | grep "^PAPERLESS_DBPASS=" | cut -d= -f2- || echo "")

    # Defaults for anything not detected
    DETECTED_DB_HOST="${DETECTED_DB_HOST:-db}"
    DETECTED_DB_NAME="${DETECTED_DB_NAME:-paperless}"
    DETECTED_DB_USER="${DETECTED_DB_USER:-paperless}"

    return 0
}

detect_pgvector() {
    # Check if the Postgres container has pgvector available
    local db_container=""

    if [[ -n "${PAPERLESS_COMPOSE_PROJECT:-}" ]]; then
        db_container=$(docker ps --filter "label=com.docker.compose.project=${PAPERLESS_COMPOSE_PROJECT}" --format "{{.ID}} {{.Image}}" 2>/dev/null | grep -i "postgres" | awk '{print $1}' | head -1)
    fi

    if [[ -z "$db_container" ]]; then
        return 1
    fi

    DB_CONTAINER_ID="$db_container"
    DB_IMAGE=$(docker inspect "$db_container" --format '{{.Config.Image}}' 2>/dev/null || echo "")

    # Check if pgvector extension is available
    if docker exec "$db_container" psql -U "${DETECTED_DB_USER}" -d "${DETECTED_DB_NAME}" -c "SELECT 1 FROM pg_available_extensions WHERE name = 'vector'" 2>/dev/null | grep -q "1"; then
        return 0  # pgvector is available
    fi

    return 1
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
}

collect_addon_config() {
    echo "  We found Paperless NGX running on this server."
    echo
    info "Container: $(docker inspect "$PAPERLESS_CONTAINER_ID" --format '{{.Name}}' 2>/dev/null | sed 's/^\///')"
    [[ -n "$PAPERLESS_COMPOSE_DIR" ]] && info "Compose dir: $PAPERLESS_COMPOSE_DIR"
    info "DB host: ${DETECTED_DB_HOST}"
    info "DB name: ${DETECTED_DB_NAME}"

    divider

    echo "  We'll add semantic search to your existing Paperless installation."
    echo "  Your existing setup will not be modified (we use a docker-compose.override.yml)."
    echo

    if ! prompt_yn "Continue?"; then
        echo "  Cancelled."
        exit 0
    fi

    divider

    echo "  We need your Paperless admin credentials so the companion"
    echo "  container can access the Paperless API."
    echo
    ADMIN_USER=$(prompt_safe "Paperless admin username" "admin")
    ADMIN_PASSWORD=$(prompt_secret "Paperless admin password")

    divider

    # Confirm DB connection details
    echo "  Confirm your database connection:"
    echo
    DB_HOST=$(prompt_safe "Postgres host (Docker service name)" "$DETECTED_DB_HOST")
    DB_NAME=$(prompt_safe "Postgres database" "$DETECTED_DB_NAME")
    DB_USER=$(prompt_safe "Postgres user" "$DETECTED_DB_USER")
    if [[ -n "$DETECTED_DB_PASS" ]]; then
        if [[ "$DETECTED_DB_PASS" =~ [\'\"\`\\\$\#] ]]; then
            warn "Detected DB password contains special characters."
            warn "Please enter it manually."
            DB_PASS=$(prompt_secret "Postgres password")
        else
            DB_PASS="$DETECTED_DB_PASS"
            info "Database password read from existing config"
        fi
    else
        DB_PASS=$(prompt_secret "Postgres password")
    fi

    divider

    echo "  Do you have a domain name pointed at this server?"
    echo -e "  ${DIM}(e.g., docs.smithfarms.com)${NC}"
    echo
    DOMAIN=$(prompt_domain "Domain (or press Enter to skip)")
    if [[ -n "$DOMAIN" ]]; then
        LE_EMAIL=$(prompt_safe "Email for SSL certificate (Let's Encrypt)" "")
    fi

    MCP_AUTH_TOKEN=$(generate_password)
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

volumes:
  pgdata:
  redisdata:
  paperless-data:
  paperless-media:
  paperless-export:
  paperless-consume:
  caddy-data:
  caddy-config:
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
        warn "Your Postgres doesn't have pgvector."
        if [[ -n "${DB_IMAGE:-}" ]]; then
            echo "  Current image: $DB_IMAGE"
        fi
        echo
        echo "  We'll override the Postgres image to pgvector/pgvector:pg16"
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

    # Determine internal Paperless URL
    local paperless_internal_url="http://${PAPERLESS_SERVICE_NAME}:8000"

    # Generate docker-compose.override.yml
    local override_content="# Paperless Ag add-on -- generated by installer
# This file is automatically loaded by docker compose.
services:"

    # Add pgvector override if needed
    if [[ "${NEEDS_PGVECTOR_OVERRIDE:-}" == "true" ]]; then
        override_content+="
  ${DB_HOST}:
    image: pgvector/pgvector:pg16"
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
ENVFILE
    chmod 600 "$compose_dir/paperless-ag.env"

    # Expose MCP port directly when no domain/Caddy is configured
    if [[ -z "${DOMAIN:-}" ]]; then
        override_content+="
    ports:
      - \"3001:3001\""
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
      - companion

volumes:
  caddy-data:
  caddy-config:"
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

    # Print summary
    print_addon_summary "$compose_dir"
}

# ── File Generators ──────────────────────────────────────

generate_caddyfile() {
    local filepath="$1"
    local paperless_service="${PAPERLESS_SERVICE_NAME:-paperless}"

    if [[ -n "${DOMAIN:-}" ]]; then
        local tls_block=""
        if [[ -n "${LE_EMAIL:-}" ]]; then
            tls_block=$'\n    tls '"$LE_EMAIL"
        fi
        cat > "$filepath" <<CADDY
${DOMAIN} {${tls_block}
    handle_path /mcp/* {
        reverse_proxy companion:3001
    }
    handle {
        reverse_proxy ${paperless_service}:8000
    }
}
CADDY
    else
        cat > "$filepath" <<CADDY
:80 {
    handle_path /mcp/* {
        reverse_proxy companion:3001
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
            warn "Could not set up cron job. Run manually: bash $install_dir/backup.sh"
        fi
    fi
}

# ── Summary Output ───────────────────────────────────────

print_fresh_summary() {
    local install_dir="$1"
    local paperless_url="$2"
    local mcp_url="${paperless_url}/mcp/sse"

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
    echo -e "  ${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "  ${BOLD}CONNECT TO CLAUDE:${NC}"
    echo
    echo "  In Claude Code, run this command:"
    echo
    echo -e "    ${BOLD}claude mcp add --transport sse paperless-ag ${mcp_url} \\${NC}"
    echo -e "    ${BOLD}  --header \"Authorization: Bearer ${MCP_AUTH_TOKEN}\"${NC}"
    echo
    echo "  Or add this to your .mcp.json:"
    echo
    echo "    {"
    echo "      \"mcpServers\": {"
    echo "        \"paperless-ag\": {"
    echo "          \"type\": \"sse\","
    echo "          \"url\": \"${mcp_url}\","
    echo "          \"headers\": {"
    echo "            \"Authorization\": \"Bearer ${MCP_AUTH_TOKEN}\""
    echo "          }"
    echo "        }"
    echo "      }"
    echo "    }"
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
        mcp_url="https://${DOMAIN}/mcp/sse"
    else
        mcp_url="http://${ip_addr}:3001/sse"
    fi

    echo
    echo -e "${BOLD}════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  Paperless Ag installed!${NC}"
    echo -e "${BOLD}════════════════════════════════════════════════════${NC}"
    echo
    echo "  Semantic search is now active. Your existing Paperless"
    echo "  documents will be embedded automatically (check logs)."
    echo
    echo -e "  ${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "  ${BOLD}CONNECT TO CLAUDE:${NC}"
    echo
    echo "  In Claude Code, run this command:"
    echo
    echo -e "    ${BOLD}claude mcp add --transport sse paperless-ag ${mcp_url} \\${NC}"
    echo -e "    ${BOLD}  --header \"Authorization: Bearer ${MCP_AUTH_TOKEN}\"${NC}"
    echo
    echo "  Or add this to your .mcp.json:"
    echo
    echo "    {"
    echo "      \"mcpServers\": {"
    echo "        \"paperless-ag\": {"
    echo "          \"type\": \"sse\","
    echo "          \"url\": \"${mcp_url}\","
    echo "          \"headers\": {"
    echo "            \"Authorization\": \"Bearer ${MCP_AUTH_TOKEN}\""
    echo "          }"
    echo "        }"
    echo "      }"
    echo "    }"
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

    # Detect existing Paperless NGX
    PAPERLESS_CONTAINER_ID=""
    PAPERLESS_COMPOSE_DIR=""
    PAPERLESS_COMPOSE_PROJECT=""
    PAPERLESS_SERVICE_NAME="paperless"
    NEEDS_PGVECTOR_OVERRIDE=""

    if detect_paperless; then
        echo "  How would you like to install Paperless Ag?"
        echo
        echo "    1) Add to my existing Paperless NGX (recommended)"
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
        echo "  No existing Paperless NGX found. Setting up a fresh install."
        divider
        collect_fresh_config
        do_fresh_install
    fi
}

main "$@"
