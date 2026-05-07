#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${PAPERLESS_URL:-http://localhost:8000}"
USER_NAME="${PAPERLESS_USER:-admin}"
PASSWORD="${PAPERLESS_PASSWORD:-admin}"
QUERY="${1:-hydraulic hose}"

TOKEN="$(
  curl -sS -X POST "$BASE_URL/api/token/" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$USER_NAME\",\"password\":\"$PASSWORD\"}" |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])'
)"

SETTINGS="$(
  curl -sS "$BASE_URL/api/ui_settings/" \
    -H "Authorization: Token $TOKEN" |
    python3 -c '
import json
import sys

data = json.load(sys.stdin)
settings = data.get("settings", {})
general = settings.setdefault("general_settings", {})
dark_mode = general.setdefault("dark_mode", {})
dark_mode["use_system"] = False
dark_mode["enabled"] = "false"
print(json.dumps(settings))
'
)"

curl -sS -X POST "$BASE_URL/api/ui_settings/" \
  -H "Authorization: Token $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"settings\":$SETTINGS}" >/dev/null
echo "Set Paperless UI to light mode"

matching_ids() {
  python3 -c '
import json
import sys

data = json.load(sys.stdin)
for doc in data.get("results", []):
    original = (doc.get("original_file_name") or "").strip()
    title = (doc.get("title") or "").lower()
    content = (doc.get("content") or "").lower()
    if original in {"hand written note.png", "hand_written_note.png"} or (
        "hydraulic hose" in content and "south hay lot" in content
    ) or ("hand written note" in title):
        print(doc["id"])
'
}

DOCS_JSON="$(curl -sS "$BASE_URL/api/documents/?query=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$QUERY")&page_size=100" \
  -H "Authorization: Token $TOKEN")"

IDS="$(printf '%s' "$DOCS_JSON" | matching_ids)"

while IFS= read -r id; do
  [[ -z "$id" ]] && continue
  curl -sS -X DELETE "$BASE_URL/api/documents/$id/" \
    -H "Authorization: Token $TOKEN" >/dev/null
  echo "Moved document $id to trash"
done <<<"$IDS"

TRASH_JSON="$(curl -sS "$BASE_URL/api/trash/?page_size=100" \
  -H "Authorization: Token $TOKEN")"
TRASH_IDS="$(printf '%s' "$TRASH_JSON" | matching_ids)"

if [[ -z "$TRASH_IDS" ]]; then
  echo "No prior handwritten-note upload found."
  exit 0
fi

JSON_IDS="$(
  printf '%s\n' "$TRASH_IDS" |
    python3 -c 'import json,sys; print(json.dumps([int(x) for x in sys.stdin.read().split()]))'
)"

curl -sS -X POST "$BASE_URL/api/trash/" \
  -H "Authorization: Token $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"documents\":$JSON_IDS,\"action\":\"empty\"}" >/dev/null
echo "Permanently removed trash documents $JSON_IDS"
