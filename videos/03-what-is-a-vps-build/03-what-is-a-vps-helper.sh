#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="/Users/brian/github/nerdoutinc/ai-skills/screen-studio"
CLICLICK="/opt/homebrew/bin/cliclick"
SCROLL_WHEEL="$SKILL_DIR/scripts/scroll-wheel.swift"

activate_app() {
  osascript - "$1" <<'APPLESCRIPT'
on run argv
  tell application (item 1 of argv) to activate
end run
APPLESCRIPT
}

hide_process() {
  local name="$1"
  osascript - "$name" <<'APPLESCRIPT' >/dev/null 2>&1 || true
on run argv
  set processName to item 1 of argv
  tell application "System Events"
    if exists process processName then
      set visible of process processName to false
    end if
  end tell
end run
APPLESCRIPT
}

switch_tab() {
  local tab_key="$1"
  osascript - "$tab_key" <<'APPLESCRIPT'
on run argv
  set tabKey to item 1 of argv
  tell application "Helium" to activate
  delay 0.2
  tell application "System Events"
    keystroke tabKey using command down
    delay 0.2
    key code 115
  end tell
end run
APPLESCRIPT
  sleep 0.4
  "$CLICLICK" -e 200 m:825,470
}

long_scroll() {
  "$SCROLL_WHEEL" trackpad 46 down 0.018 0.14 "6,12,22,34,48,64,76,64,48,34,22,12,6"
}

case "${1:-}" in
  reset)
    activate_app "Helium"
    switch_tab 1
    switch_tab 2
    switch_tab 1
    ;;
  scroll-tab1)
    switch_tab 1
    long_scroll
    ;;
  scroll-tab2)
    switch_tab 2
    long_scroll
    ;;
  two-tab-scroll)
    switch_tab 1
    long_scroll
    sleep 1
    switch_tab 2
    long_scroll
    ;;
  hide-workbench)
    hide_process "Codex"
    hide_process "Code"
    hide_process "Xcode"
    hide_process "Docker Desktop"
    hide_process "Terminal"
    ;;
  *)
    echo "usage: $0 reset|scroll-tab1|scroll-tab2|two-tab-scroll|hide-workbench" >&2
    exit 64
    ;;
esac
