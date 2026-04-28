#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
PROJECTS="$HOME/Screen Studio Projects"

restore_codex() {
  osascript -e 'tell application "Codex" to activate' >/dev/null 2>&1 || true
}

reset_claude_config() {
  local tmp

  tmp="$(mktemp)"
  jq 'del(.mcpServers)' "$CFG" > "$tmp" && cp "$tmp" "$CFG"
  rm -f "$tmp"
}

quit_claude_and_wait() {
  osascript -e 'tell application "Claude" to quit' >/dev/null 2>&1 || true
  for _ in {1..80}; do
    if ! pgrep -x Claude >/dev/null 2>&1; then
      break
    fi
    sleep 0.25
  done
  for _ in {1..40}; do
    if ! pgrep -f 'mcp-remote.*localhost:3001/mcp' >/dev/null 2>&1; then
      break
    fi
    sleep 0.25
  done
}

prepare_helium_start() {
  osascript -e 'tell application "Helium" to quit' >/dev/null 2>&1 || true
  for _ in {1..60}; do
    if ! pgrep -x Helium >/dev/null 2>&1; then
      break
    fi
    sleep 0.25
  done

  open -a Helium 'http://localhost:8000/documents?sort=created&reverse=1&page=1'
  sleep 8
  osascript -e 'tell application "Helium" to activate' >/dev/null
  sleep 0.5
  osascript <<'APPLESCRIPT' >/dev/null
tell application "System Events"
  keystroke "s" using {command down, option down}
end tell
APPLESCRIPT
  sleep 0.5
  cliclick -e 300 m:1200,390 w:150 c:. >/dev/null 2>&1 || true
  sleep 0.5
}

cleanup_visible_apps() {
  osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
tell application "System Events"
  if exists process "Finder" then set visible of process "Finder" to false
  if exists process "Safari" then set visible of process "Safari" to false
  if exists process "Code" then set visible of process "Code" to false
  if exists process "Claude" then set visible of process "Claude" to false
  if exists process "Codex" then set visible of process "Codex" to false
end tell

tell application "Screen Studio" to activate
delay 0.3
tell application "System Events"
  if exists process "Screen Studio" then
    tell process "Screen Studio"
      repeat with w in windows
        set subroleName to ""
        try
          set subroleName to subrole of w
        end try
        if subroleName is "AXStandardWindow" then
          try
            set value of attribute "AXMinimized" of w to true
          end try
        end if
      end repeat
    end tell
  end if
end tell

tell application "System Events"
  if exists process "Screen Studio" then set visible of process "Screen Studio" to false
end tell
APPLESCRIPT
}

screenstudio_project_window_count() {
  osascript <<'APPLESCRIPT' 2>/dev/null || echo 999
tell application "System Events"
  if not (exists process "Screen Studio") then return 0
  tell process "Screen Studio"
    set visibleCount to 0
    repeat with w in windows
      set subroleName to ""
      set isMinimized to false
      try
        set subroleName to subrole of w
      end try
      try
        set isMinimized to value of attribute "AXMinimized" of w
      end try
      if subroleName is "AXStandardWindow" and isMinimized is false then
        set visibleCount to visibleCount + 1
      end if
    end repeat
    return visibleCount
  end tell
end tell
APPLESCRIPT
}

process_visible() {
  local process="$1"

  osascript -e "tell application \"System Events\" to if exists process \"$process\" then return visible of process \"$process\" else return false" 2>/dev/null || echo false
}

trap restore_codex EXIT

reset_claude_config
quit_claude_and_wait
cleanup_visible_apps
prepare_helium_start

front="$(osascript -e 'tell application "System Events" to return name of first application process whose frontmost is true' 2>/dev/null || true)"
ss_project_windows="$(screenstudio_project_window_count)"
code_visible="$(process_visible Code)"
claude_visible="$(process_visible Claude)"
codex_visible="$(process_visible Codex)"
printf 'preflight front=%s ScreenStudioProjectWindows=%s Code=%s Claude=%s Codex=%s\n' \
  "$front" "$ss_project_windows" "$code_visible" "$claude_visible" "$codex_visible"
if [[ "$front" != "Helium" ]]; then
  echo 'Preflight failed: Helium is not frontmost.' >&2
  exit 10
fi
if [[ "$ss_project_windows" != "0" ]]; then
  echo 'Preflight failed: Screen Studio project/recording window is still visible.' >&2
  exit 11
fi
if [[ "$code_visible" != "false" || "$claude_visible" != "false" || "$codex_visible" != "false" ]]; then
  echo 'Preflight failed: a non-target workbench app is still visible.' >&2
  exit 12
fi

before_latest="$(ls -td "$PROJECTS"/*.screenstudio 2>/dev/null | head -1 || true)"
printf 'before_latest=%s\n' "$before_latest"

osascript <<'APPLESCRIPT'
tell application "Screen Studio" to activate
delay 0.4
tell application "System Events"
  tell process "Screen Studio"
    click menu item "Record display" of menu "Record" of menu bar item "Record" of menu bar 1
  end tell
end tell
APPLESCRIPT
start_status=$?
printf 'start_status=%s\n' "$start_status"
sleep 3

runner_status=0
bash "$SCRIPT_DIR/02-what-we-added-keeper.sh" || runner_status=$?
printf 'runner_status=%s\n' "$runner_status"

osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
tell application "System Events"
  key code 36 using {command down, control down}
end tell
APPLESCRIPT
sleep 8
restore_codex

after_latest="$(ls -td "$PROJECTS"/*.screenstudio 2>/dev/null | head -1 || true)"
printf 'after_latest=%s\n' "$after_latest"
if [[ -n "$after_latest" && "$after_latest" != "$before_latest" && -f "$after_latest/recording/channel-1-display-0.mp4" ]]; then
  ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 "$after_latest/recording/channel-1-display-0.mp4"
else
  echo 'No fresh Screen Studio project detected.' >&2
fi
exit "$runner_status"
