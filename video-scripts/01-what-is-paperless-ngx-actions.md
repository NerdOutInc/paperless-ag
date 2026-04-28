# 01 - What Is Paperless NGX - Screencast Notes

Source audio: `01 - What is Paperless NGX.m4a`
Duration: 2:00

Transcript note: Whisper heard "Fullstack Egg"; use "Fullstack Ag" in any
on-screen or production notes.

## Recording Setup

- Record the full display, with Helium as the main target window.
- Open Paperless NGX in Helium and log out before recording so the first frame is
  the login page.
- After logging out, refresh the browser or navigate back to
  `http://localhost:8000/accounts/login/` so the login page does not show the
  "You have signed out." banner when the recording starts.
- Before starting a take, confirm the first frame is a quiet login page with no
  notification banner, modal, dropdown, or Screen Studio project window visible.
- Log in on camera with the demo credentials `admin` / `admin`.
- Resize and position Helium with Breeze using `Command + Option + S`.
- After login, start the document walkthrough with no active search or filters.
- Keep Paperless NGX at a stable zoom level, ideally 100 percent.
- Run two dry/test runs before the Screen Studio keeper:
  discovery first, command validation second.
- During the first dry run, record the exact `cliclick` commands and
  coordinates in this file as each interaction is discovered.
- During the second dry run, execute the recorded commands from this file,
  inspect the screen after each action, and update coordinates or waits until
  the whole sequence works without manual correction.

## Preflight Data

Make sure the Paperless archive has visible examples for:

- Login credentials: `admin` / `admin`
- Keyword search: `nitrogen`
- Tag: `insurance`
- Lease examples: `lease agreement` or the `lease` tag/type
- Metadata fields: date, tags, correspondent/from, and document type

## Coordinate Discovery Workflow

Use the first dry run to discover coordinates, not to record video.

1. Set Helium with Breeze using `Command + Option + S`.
2. Log out, then refresh the login page so the sign-out banner disappears.
3. Perform each action by hand with `cliclick`.
4. Immediately write the working `cliclick` command into this file.
5. Take a screenshot or otherwise inspect the screen after every action.
6. Do not continue until Paperless visibly reaches the expected state.

Use the second dry run to execute the recorded commands.

1. Reset to the clean login page.
2. Run the command sequence below without Screen Studio.
3. After each interaction, confirm the expected state in the checklist below.
4. Update this file if any coordinate, wait, or typed input is wrong.
5. Start Screen Studio only after this command sequence passes.

## Working Coordinates

These are the best-known coordinates with Helium positioned by Breeze on the
built-in Retina display. The login coordinates assume the sign-out banner has
been cleared by refreshing the login page. Re-discover them during the first dry
run if the display, window position, zoom level, or Paperless layout changes.

| Target | `cliclick` coordinate | Expected state |
| --- | --- | --- |
| Screen Studio display picker | `m:420,905 c:.` | Full display capture is selected. |
| Screen Studio start button | `m:757,547 c:.` | Recording begins. |
| Login username field | `m:756,520 c:.` | Username field receives focus. |
| Login password field | `m:756,575 c:.` | Password field receives focus. |
| Login submit button | `m:756,650 c:.` | Dashboard opens. |
| Documents sidebar item | `m:250,267 c:.` | Documents archive opens. |
| Paperless search field | `m:620,174 c:.` | Search input receives focus. |
| Paperless search submit | `m:800,174 c:.` | Search results update. |
| Reset filters link | `m:595,390 c:.` | Filters clear. |
| Blank list focus area | `m:1200,390 c:.` | Page focus returns to the document list without opening a document or desktop. |
| Tags dropdown | `m:439,343 c:.` | Tags menu opens. |
| `insurance` tag option | `m:465,470 c:.` | Insurance tag filter is applied. |
| First insurance preview button | `m:502,782 c:.` | Insurance document preview opens in a new tab. |

## Dry Run Command Sequence

Update this block during the first dry run, then run it during the second dry
run before starting Screen Studio.

```bash
smooth_scroll_down_and_back() {
  local down_steps="${1:-24}"
  local up_steps="${2:-18}"
  local delay="${3:-0.025}"

  osascript <<APPLESCRIPT
tell application "System Events"
  repeat ${down_steps} times
    key code 125
    delay ${delay}
  end repeat
  delay 0.30
  repeat ${up_steps} times
    key code 126
    delay ${delay}
  end repeat
end tell
APPLESCRIPT
}

# Clean start. Log out, then refresh or navigate to the login page so the
# "You have signed out." banner is gone before recording.
osascript -e 'tell application "Helium" to activate'
sleep 0.3
osascript <<'APPLESCRIPT'
tell application "System Events"
  tell process "Helium"
    keystroke "l" using {command down}
    delay 0.05
    keystroke "http://localhost:8000/accounts/logout/"
    key code 36
    delay 1.5
    keystroke "r" using {command down}
  end tell
end tell
APPLESCRIPT
sleep 2.0

# Login.
/opt/homebrew/bin/cliclick -e 280 -w 90 m:756,520 c:. t:admin
/opt/homebrew/bin/cliclick -e 280 -w 90 m:756,575 c:. t:admin
/opt/homebrew/bin/cliclick -e 280 -w 90 m:756,650 c:.
sleep 6.2

# Documents and archive introduction.
/opt/homebrew/bin/cliclick -e 300 -w 90 m:250,267 c:.
sleep 3.5
/opt/homebrew/bin/cliclick -e 260 -w 90 m:1200,390 c:.
sleep 0.3
smooth_scroll_down_and_back 26 26 0.025
sleep 4.0
/opt/homebrew/bin/cliclick -e 300 -w 120 \
  m:695,548 w:1800 m:1038,690 w:1600 m:756,232
sleep 10.0

# Nitrogen search.
/opt/homebrew/bin/cliclick -e 300 -w 90 m:620,174 c:. t:nitrogen
sleep 1.4
/opt/homebrew/bin/cliclick -e 300 -w 90 m:800,174 c:.
sleep 3.0
/opt/homebrew/bin/cliclick -e 260 -w 90 m:1200,390 c:.
sleep 0.3
smooth_scroll_down_and_back 18 18 0.025
sleep 5.4
/opt/homebrew/bin/cliclick -e 300 -w 90 m:595,390 c:.
sleep 3.2

# Insurance tag filter and detail view.
/opt/homebrew/bin/cliclick -e 300 -w 90 m:439,343 c:.
sleep 1.0
/opt/homebrew/bin/cliclick -e 300 -w 90 t:insurance
sleep 1.0
/opt/homebrew/bin/cliclick -e 300 -w 90 m:465,470 c:.
sleep 1.8
/opt/homebrew/bin/cliclick -e 260 -w 90 m:1200,390 c:.
sleep 0.3
smooth_scroll_down_and_back 14 14 0.025
sleep 2.8
# The list-focus click also dismisses the tag dropdown before opening a result.
/opt/homebrew/bin/cliclick -e 300 -w 90 m:502,782 c:.
sleep 11.0
osascript <<'APPLESCRIPT'
tell application "System Events"
  tell process "Helium"
    keystroke "w" using {command down}
  end tell
end tell
APPLESCRIPT
sleep 1.0

# Lease search and closing archive.
/opt/homebrew/bin/cliclick -e 300 -w 90 m:250,267 c:.
sleep 2.6
/opt/homebrew/bin/cliclick -e 300 -w 90 m:595,390 c:.
sleep 2.2
/opt/homebrew/bin/cliclick -e 300 -w 90 m:620,174 c:. t:lease
sleep 1.4
/opt/homebrew/bin/cliclick -e 300 -w 90 m:800,174 c:.
sleep 3.0
/opt/homebrew/bin/cliclick -e 260 -w 90 m:1200,390 c:.
sleep 0.3
smooth_scroll_down_and_back 18 18 0.025
sleep 8.1
/opt/homebrew/bin/cliclick -e 300 -w 90 m:595,390 c:.
sleep 2.2
/opt/homebrew/bin/cliclick -e 300 -w 90 m:700,520
sleep 25.0
```

## Dry Run Log

- 2026-04-24 discovery run: Helium was positioned by Breeze at
  `184,50,1142,813` on the built-in Retina display. Clean login page verified
  with no sign-out banner.
- Login coordinates, Documents sidebar, keyword search, Reset filters, Tags
  dropdown, `insurance` option, insurance result, lease search, and final reset
  coordinates all matched the working table above.
- The Tags dropdown did not close with `kp:esc`; the keeper sequence now leaves
  the dropdown open briefly, then clicks the first insurance result at
  `m:437,782 c:.`, which reliably opens the document detail page and dismisses
  the menu.
- Source audio duration measured with `ffprobe`: `120.418685` seconds.
- Screen Studio smoke test passed:
  `/Users/brian/Screen Studio Projects/Built-in Retina Display 2026-04-24 15:28:30.screenstudio`
  with a `2.740000` second display track.
- First keeper take saved at
  `/Users/brian/Screen Studio Projects/Built-in Retina Display 2026-04-24 15:36:36.screenstudio`
  with a `117.881667` second display track; this was slightly short for the
  narration target, so a second keeper was recorded.
- Final keeper take saved at
  `/Users/brian/Screen Studio Projects/Built-in Retina Display 2026-04-24 15:53:19.screenstudio`
  with a `123.771667` second display track.
- 2026-04-24 scroll-change validation: an early focus click at `m:1350,480`
  landed just outside Helium and triggered the macOS desktop/widgets view. The
  blank focus target was moved inside Helium to `m:1200,390`.
- Scroll calls now return fully to the top before the next scripted click:
  archive `26/26`, nitrogen `18/18`, insurance `14/14`, and lease `18/18`.
- The insurance card title and document action hit filters/selection in card
  view. The keeper now opens the insurance document with the eye preview button
  at `m:502,782 c:.`, then closes the preview tab with `Command + W` before the
  lease segment.
- Final dry validation for the scroll-change sequence passed: full archive,
  nitrogen results, insurance results, and lease results all visibly scrolled;
  the preview tab opened and closed back to the Documents list.
- Scroll-change keeper take saved at
  `/Users/brian/Screen Studio Projects/Built-in Retina Display 2026-04-24 19:20:24.screenstudio`
  with a `126.516667` second display track.
- Clean-window keeper take saved at
  `/Users/brian/Screen Studio Projects/Built-in Retina Display 2026-04-27 12:57:34.screenstudio`
  with a `127.143333` second display track. Other visible apps were hidden
  before recording so no window protruded behind Helium.

## Screen State Checks

After each interaction in the dry runs, take a screenshot or visually inspect
the app before moving on.

| Step | Expected visible result |
| --- | --- |
| Logout and refresh | Login page with no "You have signed out." banner. |
| Submit login | Dashboard with "Successfully signed in" notification. |
| Click Documents | Documents page with 100 documents and no filters. |
| Search `nitrogen` | Filtered results with nitrogen-tagged documents. |
| Reset filters | Full document archive returns. |
| Open Tags | Tags dropdown is visible with a filter input. |
| Select `insurance` | Results show an insurance tag chip and 9 documents. |
| Open document | Insurance document preview opens with policy details visible. |
| Search `lease` | Lease results are visible. |
| Final reset | Full document archive is visible for the closing hold. |

## Timeline

| Time | Narration Cue | Screen Action |
| --- | --- | --- |
| 00:00-00:06 | "Hey this is Brian from Fullstack Ag..." | Start on the Paperless NGX login page in Helium. Type `admin` / `admin` and submit the login form. |
| 00:06-00:18 | "years of paperwork sitting in filing cabinets..." | After login, click the `Documents` link. When the archive appears, smoothly scroll the document grid down and back up with small trackpad-like scrolls so it feels like a real archive. Avoid opening a document yet. |
| 00:18-00:30 | "Paperless NGX is a free open source app..." | Click or hover a representative document row so the preview/metadata area becomes visible. Show that the paper archive is now digital. |
| 00:30-00:37 | "scan a document or drop in a PDF..." | Briefly show the upload/add document area or a document preview. Do not actually upload during the final take unless rehearsed. |
| 00:37-00:43 | "take a photo of a handwritten note..." | Open a document preview or details panel where OCR/searchable text is visible. The point is to show paper becoming searchable text. |
| 00:43-00:50 | "search by keyword..." | Click into the Paperless search box. Pause a beat before typing so the action lines up with the narration. |
| 00:50-00:57 | "we'll type in nitrogen..." | Type `nitrogen`. Wait for results to update, then smoothly scroll the filtered document grid a short distance to show the result set. |
| 00:57-01:05 | "organize everything with tags and document types..." | Clear the keyword search. Click the `Tags` dropdown and pause briefly so the filter control is visible. |
| 01:05-01:12 | "take something as insurance..." | Type `insurance` inside the `Tags` dropdown, then click the `insurance` tag from the dropdown options. Let the filtered result list settle, then give the results a short smooth scroll. |
| 01:12-01:17 | "every document gets a date, tags, who it's from..." | Open one insurance result preview. Show date, correspondent/from, and policy details, then close the preview tab before continuing. |
| 01:17-01:28 | "find a lease agreement... insurance policies..." | Switch filters from insurance to lease, or search for `lease`. After the lease results appear, smoothly scroll the filtered document grid for visual interest. |
| 01:28-01:37 | "runs on your own hardware..." | Return to a stable Paperless screen. Optionally click the Helium address bar once to reveal a local URL such as `localhost:8000`, then return focus to the app. |
| 01:37-01:44 | "completely free, no subscription..." | Keep the UI steady. Let the message breathe; avoid extra clicking here. |
| 01:44-01:51 | "the very basics of Paperless NGX..." | Clear filters and return to the full document list or dashboard. |
| 01:51-02:01 | "next video... searching even smarter..." | End on the full archive or a search results view. Pause a beat after the final word before stopping the recording. |

## Rehearsal Checklist

1. Confirm the final capture is the full display.
2. Log out of Paperless, refresh, and confirm the login page is the starting
   frame with no sign-out banner.
3. Use Breeze to set Helium to the recording position.
4. Run the first dry run for discovery and write the `cliclick` commands above.
5. Run the second dry run by executing the recorded commands and updating them
   until every screen state check passes.
6. Record a Screen Studio keeper only after the second dry run succeeds.
7. Rehearse small smooth scroll gestures after opening Documents and after each
   search/filter result set. Avoid big mouse-wheel jumps.
8. Reset to the logged-out Paperless login page before the final take.

## Keeper Take Notes

- Keep cursor movement slow and intentional.
- Use small, smooth, trackpad-like scrolls for document-grid movement. Scroll only
  after the `Documents` link opens the archive and after search/filter results
  settle.
- Avoid opening menus that cover the document list unless the narration calls for it.
- Prefer showing finished search/filter states over live UI fiddling.
- Stop with `Command + Control + Return` after a short beat at the end.
