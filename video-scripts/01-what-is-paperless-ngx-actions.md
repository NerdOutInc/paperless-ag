# 01 - What Is Paperless NGX - Screencast Actions

Source audio: `garage-band/01-what-is-paperless-ngx.m4a`
Working audio copy: `video-scripts/01-what-is-paperless-ngx.m4a`
Duration: `92.183220` seconds

Transcript note: Whisper hears "Fullstack Egg" and "Paperless Egg"; production
notes should read "Fullstack Ag" and "Paperless Ag".

## Story Beats

- 0:00-0:24: Hold on a logged-in Paperless NGX Documents page and show the
  archive as a single home for farm documents. Use light mode and scroll to the
  bottom of the page before returning to the top.
- 0:24-0:44: Drag the Desktop `hand written note.png` into Paperless and let the
  upload/OCR process start.
- 0:44-1:00: Hold while Paperless reads the note and stores searchable text.
- 1:00-1:12: Search for `hydraulic hose` and show the note coming back.
- 1:12-1:22: Hold on the recovered note result.
- 1:22-end: Click the file icon button on the recovered result and hold on the
  uploaded PNG's document page as the final visual state.

## Starting State

- Capture scope: full display.
- Target app: Helium, already logged in at
  `http://localhost:8000/documents?sort=created&reverse=1&page=1`.
- Desktop source: `/Users/brian/Desktop/hand written note.png`.
- Helium window state during planning: `185,50,1141,840`.
- Desktop note position during planning: `1415,202`.
- Live-pointer coordinate checks:
  - `Documents` header: `463,240`.
  - `Title & content` input: `911,299`.
- Paperless has no active search, no active filters, no notification banners,
  light mode is enabled, and the document grid is visible.
- Codex, Terminal, Safari, and Code are hidden before keeper recording.
- Old Screen Studio project windows are minimized before keeper recording.

## Recorded Visible Sequence

1. Start on the light-mode Paperless Documents page with no filters.
2. Focus a safe blank area in the document grid.
3. Scroll down to the bottom of the current Documents page, hold briefly, then
   return to the top for a clean upload target.
4. Drag `/Users/brian/Desktop/hand written note.png` into Paperless.
5. Wait for upload, OCR, and indexing.
6. Search `hydraulic hose` in the `Title & content` field.
7. Hold briefly on the one recovered `hand written note` result.
8. Click the file icon button in the lower-left button row of that result card
   to open the uploaded PNG's document page, then hold there as the ending
   state.

## State Checks

- `http://localhost:8000` responds.
- `http://localhost:3001/health` responds `ok`.
- Recording status server is running at port `8765` before dry runs.
- Paperless UI settings have `dark_mode.use_system=false` and
  `dark_mode.enabled=false`.
- Upload reset removes only prior copies whose original file name is
  `hand written note.png`.
- After upload, the document API shows a new document with original file name
  `hand written note.png`.
- Search for `hydraulic hose` returns the uploaded note clearly enough for the
  viewer.
- The result card's file icon opens the uploaded note's document page.
- Coordinates in the helper are global macOS logical `cliclick` coordinates,
  not Retina screenshot pixels. Prefer live-pointer reads such as
  `cliclick p:.` when recalibrating.

## Dry Run Log

- 2026-05-06: Audio transcribed locally with `whisper-cli`.
- 2026-05-06: User clarified to use the Desktop
  `/Users/brian/Desktop/hand written note.png` as the on-camera source.
- 2026-05-06: Paperless stack verified healthy.
- 2026-05-06: Dry run 1 passed upload/OCR/search, creating document `114`.
  Polish issue found: search typing missed initial letters and drag left text
  selected, so the helper now clears selection before typing and holds on the
  recovered result instead of navigating again.
- 2026-05-06: Dry run 2 rejected. The Desktop file remained selected and the
  drag did not upload. Helper updated to activate Finder before starting the
  Desktop drag.
- 2026-05-06: Validation retry passed upload/OCR with document `115`.
- 2026-05-06: Validation pass with document `116` found the search field still
  missed the first characters during fast typing. Helper adjusted to click the
  left side of the `Title & content` field and type characters with a delay.
- 2026-05-06: Validation pass with document `117` still missed initial
  characters in the web field. Search entry changed to paste `hydraulic hose`
  after focusing the field.
- 2026-05-06: Validation pass with the exact `Title & content` field center
  showed a clean `hydraulic hose` filter and one visible handwritten-note
  result.
- 2026-05-06: Screen Studio smoke capture passed.
- 2026-05-06: First keeper attempt was rejected because the display track was
  only `35.180000` seconds against the `92.183220` second narration.
- 2026-05-06: Final keeper take passed visual review. The UI search used
  `title_content=hydraulic hose` and Paperless returned only document `122`,
  `hand written note`.
- 2026-05-06: Recording status server started on port `8765`; full banner and
  QR were shared in chat before the new dry runs, and status was set to
  `phase=preparing` for project `01-what-is-paperless-ngx-light-scroll`.
- 2026-05-06: Light-mode dry run found the Desktop PNG could be covered by
  workbench apps during drag. Keeper setup was adjusted to hide Codex and
  workbench apps before recording and to position the Desktop PNG at
  `{1415, 202}`.
- 2026-05-06: File-icon discovery found the correct lower-left result-card
  click target at `440,696`; the earlier target hit the wrong part of the card.
- 2026-05-06: Validation run uploaded document `124` and opened the uploaded
  PNG's document page.
- 2026-05-06: Scroll validation found that stale page focus could open a
  preview while scrolling. The helper now sends `Escape`, returns to top, and
  focuses header whitespace before the bottom-scroll beat.
- 2026-05-06: Final pre-keeper validation uploaded document `125`, scrolled to
  the bottom, returned to the top, searched `hydraulic hose`, and opened
  `/documents/125/details` without manual correction.
- 2026-05-06: Later rehearsal exposed stale search-input coordinates caused by
  confusing Retina screenshot pixels with global `cliclick` coordinates. The
  input was recalibrated from a live pointer read to `911,299`; the Documents
  header blur/focus target was read as `463,240`.
- 2026-05-06: User confirmed the shorter pacing is acceptable as long as all
  steps are performed. Helper updated to slow the Documents-page scroll and
  type `hydraulic hose` directly instead of using clipboard paste.
- 2026-05-06: Keeper retake uploaded document `133`, searched by typing
  `hydraulic hose`, opened `/documents/133/details`, and ended on the uploaded
  PNG document page. Screen Studio keystroke metadata showed printable text
  `hydraulic hose` and no Cmd-V events.
- 2026-05-06: User requested another keeper with noticeably slower scrolling
  and typing. Helper changed from Page Down jumps to small down-arrow scroll
  steps, and search entry now types one character at a time with a visible
  delay.
- 2026-05-06: Fresh slow keeper uploaded document `135`, searched by visibly
  typing `hydraulic hose`, opened `/documents/135/details`, and ended on the
  uploaded PNG document page. Status notes were empty, API search returned only
  document `135`, and Screen Studio keystroke metadata again showed typed text
  with no Cmd-V events.
- 2026-05-06: Smooth-scroll keeper used wheel-style scroll events to browse
  down the Documents page and back up before upload. It uploaded document
  `136`, visibly typed `hydraulic hose`, opened `/documents/136/details`, and
  ended on the uploaded PNG document page. Status notes were empty, API search
  returned only document `136`, and Screen Studio keystroke metadata showed
  typed text with no Cmd-V events.
- 2026-05-06: User requested the smooth scroll be about 50% faster and travel
  farther, with a wait for the upload toast to disappear before typing search.
  Helper updated to use faster wheel-scroll defaults and a 10-second
  `TOAST_CLEAR_HOLD` before search focus/typing.
- 2026-05-06: Faster smooth-scroll keeper uploaded document `137`, waited for
  the upload toast to clear, visibly typed `hydraulic hose`, opened
  `/documents/137/details`, and ended on the uploaded PNG document page. Status
  notes were empty, API search returned only document `137`, and Screen Studio
  keystroke metadata showed typed text with no Cmd-V events.
- 2026-05-06: User requested a more trackpad-like scroll feel. The scroll
  helper was updated to use several accelerated/decelerated swipe bursts down
  and back up instead of one constant wheel stream. Trackpad-burst keeper
  uploaded document `138`, waited for the upload toast to clear, visibly typed
  `hydraulic hose`, opened `/documents/138/details`, and ended on the uploaded
  PNG document page. Status notes were empty, API search returned only document
  `138`, and Screen Studio keystroke metadata showed typed text with no Cmd-V
  events.
- 2026-05-06: User requested each trackpad-style swipe travel farther and the
  duplicate local scroll helper be removed. The video helper now uses the
  canonical `screen-studio/scripts/scroll-wheel.swift` helper and a larger
  acceleration curve. Farther-trackpad keeper uploaded document `139`, waited
  for the upload toast to clear, visibly typed `hydraulic hose`, opened
  `/documents/139/details`, and ended on the uploaded PNG document page. Status
  notes were empty, API search returned only document `139`, and Screen Studio
  keystroke metadata showed typed text with no Cmd-V events.
- 2026-05-06: User said the latest recording was otherwise perfect but asked
  for each individual trackpad scroll step to travel twice as far. The default
  trackpad acceleration curve was doubled to
  `14,28,50,78,108,78,50,28,14`.
- 2026-05-06: Double-trackpad keeper uploaded document `140`, waited for the
  upload toast to clear, visibly typed `hydraulic hose`, opened
  `/documents/140/details`, and ended on the uploaded PNG document page. Status
  notes were empty, API search returned only document `140`, and Screen Studio
  keystroke metadata showed typed text with no Cmd-V events.
- 2026-05-06: User requested 50% further trackpad scroll travel while slightly
  slowing the scroll speed. The default curve changed to
  `21,42,75,117,162,117,75,42,21`, and the per-step delay changed to `0.034`.
- 2026-05-06: Farther/slower trackpad keeper uploaded document `141`, waited
  for the upload toast to clear, visibly typed `hydraulic hose`, opened
  `/documents/141/details`, and ended on the uploaded PNG document page. Status
  notes were empty, API search returned only document `141`, and Screen Studio
  keystroke metadata showed typed text with no Cmd-V events.

## Keeper Recording

- Screen Studio project folder:
  `/Users/brian/Screen Studio Projects/`
- Screen Studio project name:
  `Built-in Retina Display 2026-05-06 17:39:08.screenstudio`
- Display track duration: `48.720000` seconds.
- Audio duration: `92.183220` seconds.
- Uploaded Paperless document: `141`, `hand written note`.
- Versioned contact sheet:
  `video-scripts/01-what-is-paperless-ngx-light-scroll-farther-slower-trackpad-keeper-contact-sheet.jpg`
- Review frames:
  `/tmp/01-paperless-v11-farther-slower-trackpad-keeper-frames`
- Status-page notes:
  `notes --clear --all` returned no notes after the keeper retake.
