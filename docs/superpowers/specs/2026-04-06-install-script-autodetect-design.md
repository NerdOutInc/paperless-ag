# Install Script Auto-Detection Design

**Date:** 2026-04-06
**Status:** Approved
**Problem:** The addon install path asks users for information the script can
already detect, doesn't validate credentials before writing config, and
hardcodes `pgvector/pgvector:pg16` regardless of the existing Postgres major
version — which destroys databases running newer Postgres versions.

## Root Cause Analysis

Tested on a Digital Ocean droplet running stock Paperless NGX with
`postgres:18`. Three failures occurred:

1. The pgvector override switched `postgres:18` to `pgvector/pgvector:pg16`.
   Postgres data files are not backward-compatible between major versions, so
   pg16 initialized a fresh empty database. All Paperless tables were lost.
2. `PAPERLESS_DBPASS` was not set as an explicit env var on the Paperless
   container (Paperless NGX defaults it). The script fell back to prompting
   the user, who didn't know the value. The actual password was in the
   Postgres container's `POSTGRES_PASSWORD` env var and in
   `docker-compose.yml`.
3. No validation occurred before writing config and restarting services. The
   broken state was only discoverable by reading container logs.

## Changes

### 1. pgvector Version Matching

When the existing Postgres lacks pgvector, the script overrides the DB image.
Instead of hardcoding `pgvector/pgvector:pg16`:

- Extract the major version from the running DB container's image tag
  (e.g., `docker.io/library/postgres:18` -> `18`, `postgres:16.2` -> `16`).
- Construct `pgvector/pgvector:pg<major>`.
- Verify the image exists with `docker manifest inspect` before proceeding.
- If no matching pgvector image exists, explain the situation and exit rather
  than silently downgrading.

### 2. Credential Auto-Detection

Extract credentials from multiple sources without prompting unless all sources
fail.

**DB credentials** cascade (in priority order):

1. Paperless container env: `PAPERLESS_DBPASS`, `PAPERLESS_DBUSER`,
   `PAPERLESS_DBNAME` (existing behavior).
2. Postgres container env: `POSTGRES_PASSWORD`, `POSTGRES_USER`,
   `POSTGRES_DB` (new source).
3. Compose file parsing: grep `docker-compose.yml` for `PAPERLESS_DBPASS` or
   `POSTGRES_PASSWORD` in environment sections.
4. Env file parsing: read files referenced by `env_file:` directives in the
   compose file (e.g., `docker-compose.env`).
5. Last resort: prompt the user.

**Paperless admin credentials** cascade:

1. Paperless container env: `PAPERLESS_ADMIN_USER` /
   `PAPERLESS_ADMIN_PASSWORD`.
2. Compose file / env files: same grep approach.
3. Prompt the user. This will be needed in most cases since these env vars are
   typically only present on first run.

### 3. Pre-Flight Validation

After collecting all credentials (auto-detected or prompted), validate them
before writing any files or restarting any services.

**DB connection test:**

- `docker exec <db_container> psql -U <user> -d <dbname> -c "SELECT 1"` with
  `PGPASSWORD` set.
- On failure: show a clear message and re-prompt for the DB password.

**Paperless API test:**

- `curl` the Paperless container's published port with admin credentials
  against `/api/token/`.
- On failure: show a clear message and re-prompt for admin credentials.

**pgvector image test:**

- `docker manifest inspect pgvector/pgvector:pg<major>` to verify the image
  exists before pulling.
- On failure: explain that no pgvector image matches the Postgres version and
  exit.

### 4. Reduced Prompting Flow

The addon install becomes:

1. Choose addon vs fresh install.
2. Script displays what it auto-detected:

   ```text
   [check] Paperless: webserver (ghcr.io/paperless-ngx/paperless-ngx:latest)
   [check] Database:  db (postgres:18 -> pgvector/pgvector:pg18)
   [check] DB credentials: auto-detected from Postgres container
   [!] Paperless admin: not found in config -- need your credentials
   ```

3. Prompt only for values that could not be auto-detected.
4. Validate all credentials against live services.
5. Domain (optional).
6. Single "Continue? [Y/n]" confirmation before writing anything.

The "Confirm your database connection" section (host, database, user, password
prompts) is eliminated when credentials are auto-detected. It is replaced by
automated validation.

## Scope

Changes are limited to `docs/install.sh`, specifically the `detect_paperless`,
`detect_pgvector`, `collect_addon_config`, and `do_addon_install` functions.
No changes to the companion container code, fresh install path, or any other
files.

## Testing

Verify on a droplet with:

- `postgres:18` without pgvector (the failing case from this investigation)
- `postgres:16` without pgvector
- `pgvector/pgvector:pg16` already installed (no override needed)
- DB password set via `POSTGRES_PASSWORD` only (not in Paperless env)
- DB password set via `PAPERLESS_DBPASS` (existing behavior still works)
- Wrong admin credentials entered manually (validation catches it)
