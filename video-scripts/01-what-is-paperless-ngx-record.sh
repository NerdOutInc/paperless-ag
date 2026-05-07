#!/usr/bin/env bash
set -euo pipefail

CLICLICK="${CLICLICK:-/opt/homebrew/bin/cliclick}"
BASE_URL="${PAPERLESS_URL:-http://localhost:8000}"
USER_NAME="${PAPERLESS_USER:-admin}"
PASSWORD="${PAPERLESS_PASSWORD:-admin}"
STATUS_SERVER="${STATUS_SERVER:-/Users/brian/github/nerdoutinc/ai-skills/screen-studio/server/status-server}"
SCROLL_WHEEL="${SCROLL_WHEEL:-/Users/brian/github/nerdoutinc/ai-skills/screen-studio/scripts/scroll-wheel.swift}"

status_action() {
  if [[ "${STATUS_UPDATES:-0}" == "1" ]]; then
    "$STATUS_SERVER" update --action "$*" >/dev/null 2>&1 &
  fi
}

scroll_to_bottom_and_top() {
  local down_bursts="${1:-5}"
  local up_bursts="${2:-5}"
  local delay="${3:-0.034}"
  local pause="${4:-0.18}"
  local curve="${5:-21,42,75,117,162,117,75,42,21}"
  local bottom_pause="${6:-0.80}"

  "$SCROLL_WHEEL" trackpad "$down_bursts" down "$delay" "$pause" "$curve"
  sleep "$bottom_pause"
  "$SCROLL_WHEEL" trackpad "$up_bursts" up "$delay" "$pause" "$curve"
}

paperless_token() {
  curl -sS -X POST "$BASE_URL/api/token/" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$USER_NAME\",\"password\":\"$PASSWORD\"}" |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])'
}

set_light_mode() {
  local token settings
  token="$(paperless_token)"
  settings="$(
    curl -sS "$BASE_URL/api/ui_settings/" \
      -H "Authorization: Token $token" |
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
    -H "Authorization: Token $token" \
    -H "Content-Type: application/json" \
    -d "{\"settings\":$settings}" >/dev/null
}

prepare_desktop_note() {
  osascript <<'APPLESCRIPT'
tell application "Finder"
  try
    close every window
  end try
  set selection to {}
  set desktop position of item "hand written note.png" of desktop to {1415, 202}
  return ""
end tell
APPLESCRIPT
}

wait_for_note() {
  local token id title original
  token="$(paperless_token)"
  for _ in {1..45}; do
    read -r id title original < <(
      curl -sS "$BASE_URL/api/documents/?query=hydraulic%20hose&page_size=25" \
        -H "Authorization: Token $token" |
        python3 -c '
import json
import sys

data = json.load(sys.stdin)
for doc in data.get("results", []):
    original = doc.get("original_file_name") or ""
    title = doc.get("title") or ""
    content = (doc.get("content") or "").lower()
    if original == "hand written note.png" or (
        "hydraulic" in content and "hose" in content and "south hay lot" in content
    ):
        print(doc["id"], title.replace(" ", "_") or "-", original.replace(" ", "_") or "-")
        raise SystemExit(0)
raise SystemExit(1)
'
    ) && {
      echo "Uploaded note ready: id=$id title=$title original=$original"
      return 0
    }
    sleep 2
  done
  echo "Timed out waiting for uploaded note" >&2
  return 1
}

reset_documents_view() {
  set_light_mode
  prepare_desktop_note
  osascript <<'APPLESCRIPT'
tell application "Helium" to activate
tell application "System Events"
  tell process "Helium"
    keystroke "l" using {command down}
    delay 0.1
    keystroke "http://localhost:8000/documents?sort=created&reverse=1&page=1"
    key code 36
  end tell
end tell
APPLESCRIPT
  sleep 3
  "$CLICLICK" -e 250 -w 80 m:285,398 c:. || true
  sleep 0.4
  osascript <<'APPLESCRIPT'
tell application "Helium" to activate
tell application "System Events"
  tell process "Helium"
    keystroke "l" using {command down}
    delay 0.1
    keystroke "http://localhost:8000/documents?sort=created&reverse=1&page=1"
    key code 36
  end tell
end tell
APPLESCRIPT
  sleep 2
}

if [[ "${SKIP_RESET:-0}" != "1" ]]; then
  reset_documents_view
fi

if [[ "${SETUP_ONLY:-0}" == "1" ]]; then
  exit 0
fi

# First beat: archive as the single home.
status_action "Showing light-mode Paperless archive and scrolling to the bottom"
osascript <<'APPLESCRIPT'
tell application "System Events"
  key code 53
  key code 115
end tell
APPLESCRIPT
sleep 0.3
"$CLICLICK" -e 300 -w 90 m:760,270 c:.
sleep 0.4
scroll_to_bottom_and_top \
  "${SCROLL_DOWN_BURSTS:-5}" \
  "${SCROLL_UP_BURSTS:-5}" \
  "${SCROLL_DELAY:-0.034}" \
  "${SCROLL_BURST_PAUSE:-0.18}" \
  "${SCROLL_CURVE:-21,42,75,117,162,117,75,42,21}" \
  "${BOTTOM_PAUSE:-0.80}"
sleep "${INTRO_HOLD:-1.0}"

# Drag the Desktop photo into Paperless.
status_action "Dragging Desktop handwritten note into Paperless"
prepare_desktop_note
osascript <<'APPLESCRIPT'
tell application "Finder" to activate
APPLESCRIPT
sleep 0.4
"$CLICLICK" -e 450 -w 120 \
  dd:1415,250 \
  dm:1325,250 \
  dm:1180,320 \
  dm:980,390 \
  dm:760,470 \
  du:760,470
osascript <<'APPLESCRIPT'
tell application "Helium" to activate
APPLESCRIPT
sleep "${UPLOAD_HOLD:-4}"

status_action "Waiting for upload, OCR, and search indexing"
wait_for_note
sleep "${OCR_HOLD:-1.2}"
status_action "Waiting for upload toast to clear before searching"
sleep "${TOAST_CLEAR_HOLD:-10}"

# Search for the phrase from the note.
status_action "Searching Title & content for hydraulic hose"
osascript <<'APPLESCRIPT'
tell application "System Events"
  key code 53
end tell
APPLESCRIPT
sleep 0.3
"$CLICLICK" -e 300 -w 120 m:${SEARCH_X:-911},${SEARCH_Y:-299} c:.
sleep 0.8
osascript <<'APPLESCRIPT'
tell application "System Events"
  tell process "Helium"
    set searchText to "hydraulic hose"
    repeat with i from 1 to length of searchText
      keystroke (character i of searchText)
      delay 0.16
    end repeat
    key code 36
  end tell
end tell
APPLESCRIPT
sleep 4.5

# Leave the recovered note on screen for the final narration beat.
status_action "Opening the uploaded handwritten note document page"
osascript <<'APPLESCRIPT'
tell application "System Events"
  key code 53
end tell
APPLESCRIPT
sleep "${RESULT_CARD_HOLD:-2.0}"
"$CLICLICK" -e 350 -w 140 m:${OPEN_DOC_X:-440},${OPEN_DOC_Y:-696} c:.
sleep "${RESULT_HOLD:-9}"
