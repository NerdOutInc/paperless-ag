# 02 - What We Added - Screencast Notes

Source audio: `video-scripts/02-what-we-added.m4a`
Duration: 3:49 (`228.902313` seconds)

Transcript note: Whisper hears "Fullstack Egg", "Paperless Egg", and "cloud" in
places. Use "Fullstack Ag", "Paperless Ag", and "Claude" in production notes.

## Recording Setup

- Record the full display with Screen Studio.
- Required before every new recording: minimize all open Screen Studio
  recording/project windows so the take starts on the target app, not an old
  Screen Studio project.
- Hard stop before every new recording: verify Screen Studio has zero
  non-minimized windows. If any Screen Studio project or recording window is
  still visible, do not start the take.
- Required before every new recording: hide the Codex window and confirm it is
  not visible anywhere behind Helium or in the Screen Studio capture view.
- Required before every new recording: hide VS Code's `Code` process unless the
  current on-camera step is intentionally editing the Claude JSON config in
  VS Code.
- Required when not recording: restore the Codex window so the user can see the
  current notes, verification, and recovery work.
- Required start-state reset: quit Helium completely, then open it from scratch
  to the Paperless documents URL before starting the recording. Do not begin a
  keeper from an old Helium session.
- Avoid focusing Helium's address bar in the opening beat. Do not use
  `Command+L` to reset Paperless at the start of the keeper; load the URL during
  off-camera preflight, then click safely in the page body so no address text is
  selected when recording begins.
- Avoid visible address-bar focus for Helium site switches too. Use
  `open -a Helium <url>` for `paperless.fullstack.ag` instead of showing
  `Command+L`, selected URL text, or address suggestions on camera.
- Keep all Video 2 source artifacts in this repo:
  - `video-scripts/02-what-we-added.m4a`
  - `video-scripts/02-what-we-added-actions.md`
  - `video-scripts/02-what-we-added-record.sh`
  - `video-scripts/02-what-we-added-keeper.sh`
  - `video-scripts/02-what-we-added-check-frames.sh`
  - `video-scripts/02-what-we-added.screenstudio`
- Use the local Docker Compose stack for the demo: `db`, `redis`,
  `paperless-webserver`, and `app`.
- Start the companion with a temporary token override of
  `MCP_AUTH_TOKEN=paperless-ag-local-demo` without editing tracked Compose files.
- Use Helium for Paperless NGX and `paperless.fullstack.ag`.
- Use Claude Desktop for connector setup and the final natural-language search.
- Open Claude Settings from the macOS menu bar under the Claude app name. Do not
  use an in-app Settings button for this take.
- Clicking Claude Settings > Developer > Edit Config opens Finder with
  `claude_desktop_config.json` selected.
- Edit this file on camera:
  `~/Library/Application Support/Claude/claude_desktop_config.json`.
- Before the keeper, clear any stale VS Code editor tab for
  `claude_desktop_config.json`. A previous take left VS Code holding an old
  copy of the file; `Command+S` then showed "Failed to save ... The content of
  the file is newer." If that toast appears during a take, stop and reset.
- Add the local `paperless-ag` MCP server config as the final top-level key at
  the bottom of `claude_desktop_config.json`, after the existing preferences,
  so the pasted connector block is visible in VS Code during the recording.
- Before recording, back up the current Claude config and remove only the
  top-level `mcpServers` key/value so the recording can show adding it fresh.
- After the keeper take, restore the original Claude config.
- Resize and position windows with Breeze using `Command + Option + S`.
- Keep Helium at a stable zoom level, ideally 100 percent.
- Run two dry/test runs before the Screen Studio keeper:
  discovery first, command validation second.
- During the first dry run, record exact `cliclick` commands and coordinates in
  this file as each interaction is discovered.
- During the second dry run, execute the recorded commands from this file,
  inspect the screen after each action, and update coordinates or waits until
  the whole sequence works without manual correction.

## Preflight Data

Make sure the local demo state is ready:

- Paperless NGX is reachable at `http://localhost:8000`.
- Paperless demo credentials are `admin` / `admin`.
- Paperless has 100 demo documents.
- No-quotes directive: do not wrap the Paperless keyword search terms in
  quotation marks during the take.
- Paperless keyword search term for the on-camera keyword-fail beat:
  `fertilizer recommendations`, typed with no quotes. In the Paperless
  Title & content filter, this unquoted keyword query returns zero documents in
  the seeded demo data.
- Paperless Ag MCP health is reachable at `http://localhost:3001/health`.
- MCP auth rejects unauthenticated requests and accepts
  `Authorization: Bearer paperless-ag-local-demo`.
- MCP `tools/list` works through the same `mcp-remote` command Claude Desktop
  will use.
- `document_embeddings` covers all 100 demo documents before recording.
- Claude Desktop can connect to `paperless-ag` and answer a local document
  search before the final recording setup is reset.
- After the on-camera VS Code save, verify on disk that
  `.mcpServers["paperless-ag"]` exists before quitting/relaunching Claude.
- After relaunching Claude, verify an `mcp-remote` process for
  `http://localhost:3001/mcp` is running before asking the final question.

## Local MCP Config

Paste this config into `claude_desktop_config.json` during the proof and during
the recording:

```json
{
  "mcpServers": {
    "paperless-ag": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "http://localhost:3001/mcp",
        "--allow-http",
        "--header",
        "Authorization:Bearer paperless-ag-local-demo"
      ],
      "env": {
        "PATH": "/Users/brian/.local/share/fnm/node-versions/v24.12.0/installation/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
      }
    }
  }
}
```

## Local Startup and Proof Commands

Use these commands before recording. The first command starts the normal local
development stack with only a temporary token override.

```bash
cat >/tmp/paperless-ag-video2.override.yml <<'YAML'
services:
  app:
    environment:
      MCP_AUTH_TOKEN: paperless-ag-local-demo
YAML

docker compose \
  -f docker-compose.yml \
  -f /tmp/paperless-ag-video2.override.yml \
  up -d --build

curl -f http://localhost:8000
curl -f http://localhost:3001/health

curl -i http://localhost:3001/mcp
curl -i \
  -H 'Authorization: Bearer paperless-ag-local-demo' \
  http://localhost:3001/mcp

docker compose exec -T db psql -U paperless -d paperless \
  -c "select count(*) as embedding_rows, count(distinct document_id) as embedded_documents from document_embeddings;"
```

The `mcp-remote` proof is recorded after the stack is healthy so the same
connection path Claude Desktop uses is verified before any take.

## Pre-Recording Proof Results

- Docker stack is running the repo Compose services: `db`, `redis`, stock
  `paperless-webserver`, and companion `app`.
- The first build exposed an old `paperless-webserver` container that was not
  attached to the current Compose network. Force-recreating the Paperless
  service fixed the local state:
  `docker compose up -d --force-recreate paperless-webserver`.
- Paperless NGX responds at `http://localhost:8000` and redirects to login.
- Demo documents were loaded with `python3 upload.py` from `test-data/`; the
  Paperless API reports 100 documents.
- MCP health responds at `http://localhost:3001/health`.
- Unauthenticated MCP requests to `/mcp` return `401`.
- Authenticated JSON-RPC `initialize` succeeds with server name `Paperless Ag`
  and version `1.27.0`.
- Authenticated `tools/list` returns seven tools:
  `search_documents`, `get_document`, `list_tags`, `list_document_types`,
  `search_by_tag`, `search_by_date_range`, and `get_embedding_status`.
- Authenticated `get_embedding_status` reports `total_chunks: 103` and
  `total_docs: 100`.
- Direct database check agrees: 103 rows in `document_embeddings` covering 100
  distinct documents.
- `npx -y mcp-remote http://localhost:3001/mcp --allow-http --header
  Authorization:Bearer paperless-ag-local-demo` can list tools and call
  `get_embedding_status`.
- Claude Desktop proof succeeded with the same local config. The
  `paperless-ag` connector appeared enabled, Claude called `search_documents`,
  and the answer found Nutrient Management Plan recommendations for Horob
  Family Farms and Pattison Acres.

## Claude Config Reset

Back up and reset the Claude config before the keeper setup sequence.

```bash
CLAUDE_CFG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
BACKUP="$CLAUDE_CFG.video2-backup"

cp "$CLAUDE_CFG" "$BACKUP"
# Remove only top-level mcpServers before recording. Use a structured JSON edit,
# not a text delete, so preferences and unrelated keys stay intact.
```

After the keeper take:

```bash
cp "$BACKUP" "$CLAUDE_CFG"
```

Proof backup path used on April 28, 2026:
`~/Library/Application Support/Claude/claude_desktop_config.json.video2-backup-20260428-140253`.

Recording reset has been applied once with:

```bash
jq 'del(.mcpServers)' "$CLAUDE_CFG" > "$CLAUDE_CFG.tmp" &&
  mv "$CLAUDE_CFG.tmp" "$CLAUDE_CFG"
```

## Coordinate Discovery Workflow

Use the first dry run to discover coordinates, not to record video.

1. Start the Docker stack and prove MCP.
2. Back up the Claude config.
3. Reset Claude config by removing only `mcpServers`.
4. Set Helium with Breeze using `Command + Option + S`.
5. Open Paperless NGX at `http://localhost:8000`.
6. Perform each action by hand with `cliclick`.
7. Immediately write the working `cliclick` command into this file.
8. Take a screenshot or otherwise inspect the screen after every action.
9. Do not continue until the visible state matches the expected result.

Use the second dry run to execute the recorded commands.

1. Reset Paperless, Helium, Claude Desktop, Finder, and the config file.
2. Run the command sequence below without Screen Studio.
3. After each interaction, confirm the expected state in the checklist below.
4. Update this file if any coordinate, wait, or typed input is wrong.
5. Start Screen Studio only after this command sequence passes.

## Working Coordinates

Coordinates are discovered with windows positioned by Breeze on the built-in
Retina display. Re-discover them if the display, window position, zoom level, or
Claude layout changes.

| Target | `cliclick` coordinate | Expected state |
| --- | --- | --- |
| Screen Studio display picker | `m:420,905 c:.` | Full display capture is selected. Reuse from Video 1 only after short capture test confirms. |
| Screen Studio start button | Accessibility click on the Start recording button | Recording begins. Coordinate clicks were unreliable in the picker; clicking the exposed Start recording button in the picker created a valid short capture. |
| Helium window after Breeze | `184,50,1142,813` | Helium is placed for the standard recording layout. |
| Helium direct URL open | `open -a Helium <url>` | Helium navigates without showing address-bar focus, selected URL text, or suggestions. |
| Paperless username field | `m:756,520 c:.` | Username field receives focus if login is needed. |
| Paperless password field | `m:756,575 c:.` | Password field receives focus if login is needed. |
| Paperless login submit | `m:756,650 c:.` | Paperless dashboard opens. |
| Paperless documents sidebar | `m:250,267 c:.` | Documents page opens. |
| Paperless search field | `m:620,233 c:.` | Paperless title/content search input receives focus. |
| Paperless search submit | Keyboard: Return | Search results update. |
| Paperless blank results/list focus | `m:1200,390 c:.` | Results/list area is focused without opening a document. |
| Paperless Ag page config copy button | `m:999,492 c:.` | Claude Desktop config snippet is copied. Coordinate assumes the Claude Desktop snippet is scrolled into view with its copy button at the upper-right of the code block. |
| Claude menu bar item | `m:44,13 c:.` | Claude app menu opens. |
| Claude Settings menu item | `m:92,88 c:.` | Claude Settings window opens. |
| Claude Developer settings item | `m:246,676 c:.` | Developer settings panel opens. |
| Claude Edit Config button | `m:500,186 c:.` | Finder opens with config JSON selected. |
| Finder selected config file | Keyboard: `Command+O` | Finder shows `claude_desktop_config.json` selected in `~/Library/Application Support/Claude/`, then opens it in VS Code. |
| VS Code JSON editor | Keyboard: `Command+A`, `Command+V`, `Command+S` | Local merged config is pasted and saved in VS Code. A VS Code "file is newer" save-conflict toast is a failed state; stop and reset instead of continuing. |
| Claude input field | `m:450,302 c:.` | Chat composer receives focus. This replaces the bad `m:540,247` target, which was high enough to hit the "Learn how to use Cowork safely" link above the text box. |
| Claude connector/plus button | `m:438,352 c:.` | Add files/connectors menu opens. |
| Claude Connectors row | `m:520,497 c:.`, then Right Arrow | Connector submenu opens and shows `paperless-ag` enabled. |
| Claude response pane focus | `m:610,420 c:.` | Response pane receives focus before the scroll beat. |

## Dry Run Command Sequence

Update this block during the first dry run, then run it during the second dry
run before starting Screen Studio.

The repo-managed runner for the current keeper path is:

```bash
video-scripts/02-what-we-added-record.sh
```

After every completed take, create a timestamp-based contact sheet with the
repo-managed frame checker:

```bash
video-scripts/02-what-we-added-check-frames.sh \
  "$HOME/Screen Studio Projects/Built-in Retina Display 2026-04-28 16:17:21.screenstudio"
```

Inspect the contact sheet and zoom individual frames around risky transitions:
Paperless search, Helium site switch, Claude Settings, VS Code save, Claude
connector/query, response scroll, and the ending page.

```bash
# Command-validation dry run sequence. Reset config and prepare windows before
# running this block; do not start Screen Studio until this passes.

CFG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
LOCAL_NODE_PATH="/Users/brian/.local/share/fnm/node-versions/v24.12.0/installation/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"

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

# Off-camera preflight, before Screen Studio starts:
# quit Helium, reopen it directly to the Paperless documents URL, position it
# with Breeze, and click inside the page body. Do not use Command+L in the
# opening keeper beat because it can leave the address bar selected on camera.
osascript -e 'tell application "Helium" to activate'
sleep 4

cliclick -e 300 m:620,233 w:250 c:.
osascript -e 'tell application "System Events" to keystroke "a" using command down'
printf '%s' 'fertilizer recommendations' | pbcopy
osascript -e 'tell application "System Events" to keystroke "v" using command down'
osascript -e 'tell application "System Events" to key code 36'
sleep 16

open -a Helium 'https://paperless.fullstack.ag'
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
osascript -e 'tell application "Claude" to activate'
sleep 1
cliclick -e 300 m:44,13 w:250 c:.
sleep 0.4
cliclick -e 300 m:92,88 w:250 c:.
sleep 8
cliclick -e 300 m:246,676 w:250 c:.
sleep 4
cliclick -e 300 m:500,186 w:250 c:.
sleep 5

osascript -e 'tell application "Finder" to activate'
sleep 0.5
osascript -e 'tell application "System Events" to keystroke "o" using command down'
sleep 4
osascript -e 'tell application "Visual Studio Code" to activate'
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
  echo "Claude config save failed; stop the take and clear the stale VS Code tab."
  exit 42
fi
sleep 10

osascript -e 'tell application "Claude" to quit'
sleep 3
open -a Claude
sleep 8
if ! pgrep -fl 'mcp-remote.*localhost:3001/mcp' >/dev/null; then
  echo "Claude did not start mcp-remote; stop the take and debug the connector."
  exit 43
fi
osascript -e 'tell application "Claude" to activate'
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
osascript -e 'tell application "Helium" to activate'
sleep 0.5
open -a Helium 'https://paperless.fullstack.ag'
sleep 61
```

## Dry Run Log

- Initial setup: source audio duration measured from repo audio file:
  `228.902313` seconds.
- Initial local services before startup were stopped or created; the recording
  will start them through Docker Compose with a temporary MCP token override.
- Proof run: local stack started with
  `/tmp/paperless-ag-video2.override.yml` setting
  `MCP_AUTH_TOKEN=paperless-ag-local-demo`.
- Proof run: Paperless webserver was force-recreated once to recover from an
  old container/network state.
- Proof run: uploaded all 100 generated PDFs from `test-data/`.
- Proof run: Paperless API showed 100 documents and companion embeddings showed
  103 chunks covering 100 documents.
- Proof run: MCP auth, `tools/list`, and `get_embedding_status` passed directly
  and through `mcp-remote`.
- Proof run: Claude Desktop connected to `paperless-ag` and successfully
  answered the fertilizer recommendations question.
- Reset run: Claude config was backed up and top-level `mcpServers` was removed
  with `jq`; `preferences` remained present.
- Discovery run: Helium positioned by Breeze at `184,50,1142,813`, logged into
  Paperless with `admin` / `admin`, and confirmed the dashboard with 100
  documents.
- Discovery correction: do not use quotes around the Paperless keyword search.
  The keeper query is `fertilizer recommendations`, typed into the Paperless
  Title & content search box with no quotation marks; local API pre-check with
  `title_content=fertilizer recommendations` returns zero documents for that
  unquoted query.
- Discovery run: `https://paperless.fullstack.ag` was shown in Helium, and the
  Claude Desktop config copy button works at `m:999,492` when that code block is
  scrolled into view.
- Discovery run: Claude Settings opened from the macOS menu bar with
  `m:44,13` then `m:92,88`; Developer is `m:246,676`; Edit Config is
  `m:500,186`.
- Discovery run: Finder opens with
  `~/Library/Application Support/Claude/claude_desktop_config.json` selected.
  Use `Command+O` from Finder to open the selected JSON in VS Code for the
  keeper take.
- Discovery run: preserving preferences while adding `mcpServers` works by
  putting a merged JSON object on the clipboard, then using `Command+A`,
  `Command+V`, and `Command+S` in VS Code. Generate the merged JSON with
  `mcpServers` as the final top-level key so the Paperless Ag connector block
  appears at the bottom of the file and remains visible on camera.
- Failed take: the Screen Studio project saved at
  `~/Screen Studio Projects/Built-in Retina Display 2026-04-28 15:43:20.screenstudio`
  is not a keeper. It was clean visually and measured `241.321667` seconds, but
  VS Code showed a save-conflict toast ("The content of the file is newer"), so
  the config never saved. Claude then answered that no Paperless Ag connector
  was available.
- Failed take: the Screen Studio project saved at
  `~/Screen Studio Projects/Built-in Retina Display 2026-04-28 15:57:37.screenstudio`
  is not a keeper. The guard correctly stopped when Claude had not yet spawned
  `mcp-remote`, but a Screen Studio project window was still visible during the
  recording. Future takes must fail preflight unless Screen Studio has zero
  non-minimized windows before recording starts.
- Failed take: the Screen Studio project saved at
  `~/Screen Studio Projects/Built-in Retina Display 2026-04-28 16:06:46.screenstudio`
  is not a keeper. Screen Studio window cleanup was fixed, but the start was
  still bad because Helium was reused from an old session and the opening
  reset/focus path left visible address-bar/page-selection noise. Future takes
  must quit Helium and reopen it fresh during preflight, then avoid
  `Command+L` in the opening keeper beat.
- Failed take: the Screen Studio project saved at
  `~/Screen Studio Projects/Built-in Retina Display 2026-04-28 16:17:21.screenstudio`
  completed with `runner_status=0` and measured `219.381667` seconds, but it is
  not a keeper. Timestamp review showed a visible Helium address-bar dropdown
  while switching to `paperless.fullstack.ag`. Future takes must use
  `open -a Helium <url>` for that site switch instead of `Command+L`.
- Keeper take: the Screen Studio project saved at
  `~/Screen Studio Projects/Built-in Retina Display 2026-04-28 16:30:32.screenstudio`
  completed with `runner_status=0` and measured `229.763333` seconds. The audio
  duration is `228.902313` seconds, so the raw take is `0.861020` seconds longer
  than the narration.
- Keeper frame review: ran
  `video-scripts/02-what-we-added-check-frames.sh video-scripts/02-what-we-added.screenstudio 0 15 30 55 80 105 130 155 180 205 227`.
  The contact sheet was written to
  `/var/folders/2y/r9pn89zx3dl8d44r6vylzffr0000gn/T//paperless-ag-frame-check-02-what-we-added.jpg`.
  Review passed: no Codex or Screen Studio project windows are visible; Helium
  site switches do not show address-bar suggestions; the MCP config is visible
  at the bottom of the JSON file; Claude shows the `paperless-ag` connector; and
  the response includes fertilizer recommendation rates from the local documents.
- Keeper project moved to
  `video-scripts/02-what-we-added.screenstudio`.
- Post-keeper reset: restored
  `~/Library/Application Support/Claude/claude_desktop_config.json` from
  `~/Library/Application Support/Claude/claude_desktop_config.json.video2-backup-20260428-140253`.
  Quit Claude after restoring so the temporary local
  `mcp-remote http://localhost:3001/mcp` processes stopped.
- Recovery proof: after clearing the stale VS Code tab, writing the same config
  to disk and relaunching Claude started `mcp-remote` for
  `http://localhost:3001/mcp`, proving the connector path is healthy.
- Discovery run: after relaunch, Claude's add/connectors menu opens with
  `m:438,352`; click `m:520,497` and press Right Arrow to show the
  `paperless-ag` connector enabled.
- Validation correction: do not use `m:540,247` for the Claude composer. It can
  hit the "Learn how to use Cowork safely" link above the prompt box and open
  Safari. Use `m:450,302`, which was verified to focus the text entry area.
- Validation correction: do not submit the final Claude prompt with
  `Command+Return`. Claude labels that shortcut as "start a task and keep
  going", and it can create a background/ready task instead of navigating into
  the response. Use plain Return after the composer has focus.
- Validation pass: typing `What are my fertilizer recommendations? Search my
  Paperless Ag documents.` at `m:450,302` and submitting with plain Return
  navigated into the session, used the `paperless-ag` integration, and returned
  the Nutrient Management Plan recommendations.
- Keeper addition: after Claude begins returning the answer, focus the response
  pane at `m:610,420`, scroll down slowly through the response, then nudge back
  up and hold on the field rates plus the visible `paperless-ag` connector
  context.
- Screen Studio smoke test: clicking the picker Start recording control and
  stopping with `Command + Control + Return` created
  `~/Screen Studio Projects/Built-in Retina Display 2026-04-28 14:46:40.screenstudio`
  with `recording/channel-1-display-0.mp4`; `ffprobe` measured the display
  track at `9.123333` seconds.

## Screen State Checks

After each interaction in the dry runs, take a screenshot or visually inspect
the app before moving on.

| Step | Expected visible result |
| --- | --- |
| Start stack | Docker shows `db`, `redis`, `paperless-webserver`, and `app` running. |
| Open Paperless | Paperless is visible in Helium at `localhost:8000`. |
| Search `fertilizer recommendations` | Paperless shows zero results, with no quote characters in the search box. |
| Open Paperless Ag site | `paperless.fullstack.ag` setup instructions are visible. |
| Copy config | Claude Desktop config JSON is on the clipboard. |
| Open Claude Settings | Settings opened from Claude menu bar app menu. |
| Click Developer | Developer panel is visible. |
| Click Edit Config | Finder opens with `claude_desktop_config.json` selected. |
| Open config | The JSON file opens from `~/Library/Application Support/Claude/`. |
| Save config | Local `paperless-ag` MCP config is saved; `jq -e '.mcpServers["paperless-ag"]'` succeeds on disk. |
| Relaunch Claude | Claude Desktop restarts, reads the config, and spawns `mcp-remote` for `localhost:3001/mcp`. |
| Open connectors | `paperless-ag` connector is visible and enabled. |
| Ask fertilizer question | Claude returns semantic results from local Paperless Ag. |
| Scroll Claude response | Field rates and the `paperless-ag` connector context are visible during the wrap-up. |
| Dead-time fallback | If the narration still has time after the Claude answer scroll, switch Helium back to `paperless.fullstack.ag` and hold on the setup page. |
| Stop Screen Studio | A fresh Screen Studio project is saved. |
| Move project | Keeper package exists at `video-scripts/02-what-we-added.screenstudio`. |

## Timeline

| Time | Narration Cue | Screen Action |
| --- | --- | --- |
| 00:00-00:16 | "Hey, this is Brian from Fullstack Ag..." | Start on local Paperless NGX in Helium with documents visible. |
| 00:16-00:40 | "Let's say I'm looking for fertilizer recommendations..." | Search `fertilizer recommendations` with no quotes and show zero keyword results. |
| 00:40-01:09 | "And that's what Paperless Ag fixes..." | Switch to `paperless.fullstack.ag`; show the semantic search and local/private positioning. |
| 01:09-01:24 | "In order to use this search..." | Switch to Claude Desktop and frame Claude as the plain-English interface. |
| 01:24-01:52 | "find the Claude Desktop config JSON file..." | Open Claude Settings from the menu bar, go to Developer, click Edit Config, and show Finder selecting the JSON file. |
| 01:52-02:25 | "Here on paperless.fullstack.ag..." | Copy config from site, open selected JSON, paste local config, save. |
| 02:25-02:42 | "I will relaunch Claude Desktop..." | Quit and relaunch Claude, then show the connector list. |
| 02:42-03:20 | "What are my fertilizer recommendations?" | Ask Claude the fertilizer question and let the answer stream. |
| 03:20-03:49 | "So that's the difference..." | Slowly scroll Claude's answer and hold on the Nutrient Management Plan rates plus the `paperless-ag` connector context. If there is dead time, switch back to `paperless.fullstack.ag` and finish on the setup page. |

## Rehearsal Checklist

1. Confirm the final capture is the full display.
2. Confirm Docker stack and MCP proof pass.
3. Confirm all Screen Studio project/recording windows are minimized and the
   non-minimized Screen Studio window count is zero.
4. Quit Helium, reopen it fresh to the Paperless documents URL, use Breeze to
   position it, and click safely into the page body so the address bar is not
   focused or selected.
5. Confirm Claude config is backed up.
6. Confirm the on-camera config starts without `mcpServers`.
7. Use Breeze to set Helium and other windows to the recording position.
8. Run the first dry run for discovery and write `cliclick` commands above.
9. Run the second dry run by executing the recorded commands and updating them
   until every screen state check passes.
10. Record a Screen Studio keeper only after the second dry run succeeds.
11. Generate and inspect a timestamp-based contact sheet with
    `video-scripts/02-what-we-added-check-frames.sh`.
12. Rename or move the final project to
   `video-scripts/02-what-we-added.screenstudio`.
13. Restore the original Claude config.

## Keeper Take Notes

- Keep cursor movement slow and intentional.
- Final project path: `video-scripts/02-what-we-added.screenstudio`.
- Keeper duration: `229.763333` seconds.
- Use the menu bar for Claude Settings.
- Do not expose unrelated desktop windows or old Screen Studio project windows.
- Do not start the keeper until Claude has already been proven to connect to
  the local MCP server.
- Do not continue past the VS Code edit if the disk check for
  `.mcpServers["paperless-ag"]` fails.
- Stop with `Command + Control + Return` after a short beat at the end.
- If the script has dead time after the Claude response scroll, finish by
  showing the `paperless.fullstack.ag` setup page in Helium.
- Verify the final display track and record its duration here after the keeper:
  `229.763333` seconds.
- Verify the final display track with
  `video-scripts/02-what-we-added-check-frames.sh` and record the contact sheet
  path here after the keeper:
  `/var/folders/2y/r9pn89zx3dl8d44r6vylzffr0000gn/T//paperless-ag-frame-check-02-what-we-added.jpg`.
