#!/usr/bin/env bash
set -euo pipefail

DO_URL="https://www.digitalocean.com/solutions/vps-hosting"
PAPERLESS_URL="https://paperless.fullstack.ag"

wait_front_process() {
  local expected="$1"
  local actual=""

  for _ in {1..60}; do
    actual="$(osascript -e 'tell application "System Events" to return name of first application process whose frontmost is true' 2>/dev/null || true)"
    if [[ "$actual" == "$expected" ]]; then
      return 0
    fi
    sleep 0.25
  done

  printf 'Expected front app %s, got %s\n' "$expected" "$actual" >&2
  return 1
}

activate_helium() {
  osascript -e 'tell application "Helium" to activate' >/dev/null
  wait_front_process "Helium"
}

open_helium_url() {
  local url="$1"

  open -a Helium "$url"
  activate_helium
}

reset_helium_to_single_url() {
  local url="$1"

  osascript <<APPLESCRIPT >/dev/null
tell application "Helium"
  if (count of windows) is 0 then
    make new window
  end if
  tell front window
    repeat while (count of tabs) > 1
      close tab -1
    end repeat
    set URL of active tab to "${url}"
  end tell
  activate
end tell
APPLESCRIPT
  activate_helium
}

press_down_steps() {
  local steps="$1"
  local delay="${2:-0.045}"

  osascript <<APPLESCRIPT
tell application "System Events"
  repeat ${steps} times
    key code 125
    delay ${delay}
  end repeat
end tell
APPLESCRIPT
}

press_up_steps() {
  local steps="$1"
  local delay="${2:-0.045}"

  osascript <<APPLESCRIPT
tell application "System Events"
  repeat ${steps} times
    key code 126
    delay ${delay}
  end repeat
end tell
APPLESCRIPT
}

reset_helium_to_single_url "$DO_URL"
sleep 5

cliclick -e 300 m:1200,650 w:250 c:.
sleep 3

# Slow DigitalOcean browsing for the first minute of narration.
press_down_steps 8 0.055
sleep 7
press_down_steps 8 0.055
sleep 7
press_down_steps 8 0.055
sleep 8
press_down_steps 8 0.055
sleep 7
press_down_steps 8 0.055
sleep 8
press_down_steps 6 0.055
sleep 4

# "Here's what setting up a VPS actually looks like."
open_helium_url "$PAPERLESS_URL"
sleep 3.5

# Click the "Deploy | DigitalOcean" badge. The exact coordinate is updated by
# dry-run calibration if the page shifts.
cliclick -e 300 m:573,544 w:350 c:.
sleep 12

current_url="$(osascript -e 'tell application "Helium" to return URL of active tab of front window' 2>/dev/null || true)"
if [[ "$current_url" == *"cloud.digitalocean.com/login"* ]]; then
  echo "DigitalOcean login page reached instead of the Droplet form; log into DigitalOcean in Helium before recording." >&2
  exit 44
fi

# Droplet form: show selected size and nearby form controls without creating.
cliclick -e 300 m:1250,520 w:250 c:.
sleep 1
press_down_steps 8 0.05
sleep 9
press_down_steps 10 0.05
sleep 10
press_up_steps 5 0.05
sleep 35
