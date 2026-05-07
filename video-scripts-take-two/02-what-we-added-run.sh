#!/usr/bin/env bash
set -euo pipefail

STATUS_SERVER="/Users/brian/github/nerdoutinc/ai-skills/screen-studio/server/status-server"
SCROLL_WHEEL="/Users/brian/github/nerdoutinc/ai-skills/screen-studio/scripts/scroll-wheel.swift"
STATUS_PORT="${STATUS_PORT:-8766}"
CLAUDE_WAIT_SECONDS="${CLAUDE_WAIT_SECONDS:-180}"

PAPERLESS_URL="http://localhost:8000/documents?sort=created&reverse=1&page=1"
PROJECT_URL="https://paperless.fullstack.ag"
PAPERLESS_QUERY="fertilizer recommendations"
CLAUDE_PROMPT="What are my fertilizer recommendations? Search my Paperless Ag documents."

status() {
  "$STATUS_SERVER" update --port "$STATUS_PORT" --action "$1" >/dev/null 2>&1 || true
}

activate() {
  osascript -e "tell application \"$1\" to activate"
  sleep "${2:-0.5}"
}

system_key() {
  local script="$1"
  osascript -e "tell application \"System Events\" to $script"
}

select_all() {
  system_key 'keystroke "a" using command down'
}

open_location() {
  local url="$1"
  system_key 'keystroke "l" using command down'
  sleep 0.1
  system_key "keystroke \"$url\""
  system_key 'key code 36'
}

select_tab() {
  local tab_number="$1"
  system_key "keystroke \"$tab_number\" using command down"
  sleep 0.4
}

type_text() {
  local text="$1"
  cliclick -w 42 "t:$text"
}

setup_windows() {
  status "Resetting Helium Paperless tab with no filters"
  activate "Helium" 0.5
  select_tab 1
  open_location "$PAPERLESS_URL"
  sleep 2.6

  status "Resetting project page tab to the top"
  select_tab 2
  open_location "$PROJECT_URL"
  sleep 2.6
  cliclick kp:home
  sleep 0.4

  status "Opening a blank Claude chat"
  activate "Claude" 0.8
  system_key 'keystroke "n" using command down'
  sleep 1.4
  cliclick -e 300 c:1030,528
  sleep 0.4

  activate "Helium" 0.5
  select_tab 1
  status "Ready on Paperless Documents page"
}

paperless_search() {
  status "Typing Paperless title-content keyword search"
  cliclick -e 300 c:700,295
  sleep 0.2
  select_all
  sleep 0.1
  type_text "$PAPERLESS_QUERY"
  sleep 0.4
  system_key 'key code 36'
  sleep 2.2
  status "Paperless empty result state visible"
}

project_scroll() {
  status "Switching to project page"
  cliclick -e 300 c:560,67
  sleep 1.0
  cliclick kp:home
  sleep 0.4
  cliclick -e 300 m:900,620 c:.
  sleep 0.25
  status "Scrolling project page to the bottom"
  "$SCROLL_WHEEL" trackpad 10 down 0.04 0.28 "12,24,42,70,96,70,42,24,12"
  sleep 1.0
}

ask_claude() {
  status "Switching to Claude Desktop"
  activate "Claude" 0.9
  cliclick -e 300 c:542,311
  sleep 0.25
  status "Typing Claude fertilizer question"
  type_text "$CLAUDE_PROMPT"
  sleep 0.5
  cliclick -e 300 c:1066,370
  status "Claude question submitted with send button"
  sleep 3.0
  status "Opening active Claude response thread"
  cliclick -e 300 c:650,570
  sleep 1.5

  local elapsed=0
  while (( elapsed < CLAUDE_WAIT_SECONDS )); do
    sleep 15
    elapsed=$((elapsed + 15))
    status "Waiting for Claude response (${elapsed} seconds)"
  done

  status "Scrolling Claude response to the bottom"
  cliclick -e 300 m:900,590 c:.
  sleep 0.2
  "$SCROLL_WHEEL" trackpad 7 down 0.04 0.28 "12,24,42,70,96,70,42,24,12"
  sleep 2.0
}

case "${1:-run}" in
  setup)
    setup_windows
    ;;
  run)
    setup_windows
    paperless_search
    project_scroll
    ask_claude
    ;;
  actions)
    paperless_search
    project_scroll
    ask_claude
    ;;
  *)
    echo "usage: $0 [setup|run|actions]" >&2
    exit 2
    ;;
esac
