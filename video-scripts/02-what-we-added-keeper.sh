#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
LOCAL_NODE_PATH="/Users/brian/.local/share/fnm/node-versions/v24.12.0/installation/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"

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

activate_and_confirm() {
  local app="$1"
  local process="${2:-$app}"

  osascript -e "tell application \"$app\" to activate"
  wait_front_process "$process"
}

set_local_claude_config_clipboard() {
  jq \
    --arg node_path "$LOCAL_NODE_PATH" \
    '. + {mcpServers: {"paperless-ag": {
      command: "npx",
      args: [
        "-y",
        "mcp-remote",
        "http://localhost:3001/mcp",
        "--allow-http",
        "--header",
        "Authorization:Bearer paperless-ag-local-demo"
      ],
      env: {PATH: $node_path}
    }}} | (del(.mcpServers)) + {mcpServers: .mcpServers}' \
    "$CFG" | pbcopy
}

activate_and_confirm "Helium"
sleep 4

cliclick -e 300 m:620,233 w:250 c:.
osascript -e 'tell application "System Events" to keystroke "a" using command down'
printf '%s' 'fertilizer recommendations' | pbcopy
osascript -e 'tell application "System Events" to keystroke "v" using command down'
osascript -e 'tell application "System Events" to key code 36'
sleep 16

open -a Helium 'https://paperless.fullstack.ag'
activate_and_confirm "Helium"
sleep 5
osascript <<'APPLESCRIPT'
tell application "System Events"
  repeat 7 times
    key code 125
    delay 0.035
  end repeat
end tell
APPLESCRIPT
sleep 10
osascript <<'APPLESCRIPT'
tell application "System Events"
  repeat 20 times
    key code 125
    delay 0.035
  end repeat
end tell
APPLESCRIPT
sleep 5

cliclick -e 300 m:999,492 w:250 c:.
sleep 3
set_local_claude_config_clipboard

open -a Claude
sleep 6
activate_and_confirm "Claude"
sleep 1
cliclick -e 300 m:44,13 w:250 c:.
sleep 0.4
cliclick -e 300 m:92,88 w:250 c:.
sleep 8
cliclick -e 300 m:246,676 w:250 c:.
sleep 4
cliclick -e 300 m:500,186 w:250 c:.
sleep 5

activate_and_confirm "Finder"
sleep 0.5
osascript -e 'tell application "System Events" to keystroke "o" using command down'
sleep 4
activate_and_confirm "Visual Studio Code" "Code"
sleep 0.5
osascript <<'APPLESCRIPT'
tell application "System Events"
  keystroke "a" using command down
  delay 0.1
  keystroke "v" using command down
  delay 0.2
  keystroke "s" using command down
end tell
APPLESCRIPT
sleep 2
if ! jq -e '.mcpServers["paperless-ag"]' "$CFG" >/dev/null; then
  echo "Claude config save failed; stop the take and clear the stale VS Code tab." >&2
  exit 42
fi
sleep 10

osascript -e 'tell application "Claude" to quit'
for _ in {1..80}; do
  if ! pgrep -x Claude >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done
open -a Claude
for _ in {1..90}; do
  if pgrep -fl 'mcp-remote.*localhost:3001/mcp' >/dev/null; then
    break
  fi
  sleep 0.5
done
if ! pgrep -fl 'mcp-remote.*localhost:3001/mcp' >/dev/null; then
  echo "Claude did not start mcp-remote; stop the take and debug the connector." >&2
  exit 43
fi
activate_and_confirm "Claude"
sleep 1
cliclick -e 300 m:438,352 w:250 c:.
sleep 0.6
cliclick -e 300 m:520,497 w:250 c:.
sleep 0.3
osascript -e 'tell application "System Events" to key code 124'
sleep 6
osascript -e 'tell application "System Events" to key code 53'
sleep 0.5
cliclick -e 300 m:450,302 w:250 c:.
osascript -e 'tell application "System Events" to keystroke "What are my fertilizer recommendations? Search my Paperless Ag documents."'
sleep 0.5
osascript -e 'tell application "System Events" to key code 36'
sleep 30
cliclick -e 300 m:610,420 w:250 c:.
sleep 0.4
osascript <<'APPLESCRIPT'
tell application "System Events"
  repeat 16 times
    key code 125
    delay 0.045
  end repeat
end tell
APPLESCRIPT
sleep 8
osascript <<'APPLESCRIPT'
tell application "System Events"
  repeat 6 times
    key code 126
    delay 0.045
  end repeat
end tell
APPLESCRIPT
sleep 22

activate_and_confirm "Helium"
sleep 0.5
open -a Helium 'https://paperless.fullstack.ag'
activate_and_confirm "Helium"
sleep 61
