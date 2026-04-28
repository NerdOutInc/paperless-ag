# 03 - What Is a VPS - Screencast Notes

Source audio: `video-scripts/03-what-is-a-vps.m4a`
Duration: `129.335147` seconds.

Transcript source: local `whisper-cli` with
`~/.cache/whisper.cpp/ggml-base.en.bin`, after converting the m4a to wav with
`ffmpeg`. Whisper heard "Fullstack Egg" and "computer you write online"; use
"Fullstack Ag" and "computer you rent online" in production notes.

## Recording Setup

- Record the full display with Screen Studio, matching Videos 1 and 2.
- Keep the visible workflow inside Helium for the entire take.
- Leave Screen Studio's current audio/camera inputs unchanged. The picker
  showed no camera, no microphone, and no system audio during preflight.
- Required before every new recording: minimize or hide all old Screen Studio
  project/recording windows. The active "Start Recording" picker/window can
  remain visible while configuring the take because it hides itself when the
  recording starts.
- Required before every new recording: hide Codex and confirm it is not visible
  behind Helium or in the Screen Studio capture view.
- Required when not recording: restore Codex so the user can see notes,
  verification, and recovery work.
- Resize and position Helium with Breeze using `Command + Option + S`.
- Do not use `Command+L` on camera. Use `open -a Helium <url>` for site
  switches so the address bar and suggestions stay out of the story.
- Start on `https://www.digitalocean.com/solutions/vps-hosting`.
- Around the "Here's what setting up a VPS actually looks like" narration beat,
  switch to `https://paperless.fullstack.ag`, click the "Deploy |
  DigitalOcean" badge, and land on DigitalOcean's create Droplet form.
- Do not create a droplet.

## Audio Timeline

| Time | Narration beat | Planned screen action |
| --- | --- | --- |
| 0:00 | Intro and need somewhere to install Paperless | DigitalOcean VPS hosting hero page. |
| 0:19 | "VPS stands for Virtual Private Server" | Slow scroll through the VPS explainer page. |
| 0:38 | Data centers and rented slice of a server | Continue gentle scroll; avoid jumps and menus. |
| 0:58 | "Here's what setting up a VPS actually looks like" | Open Paperless Ag in Helium. |
| 1:02 | DigitalOcean calls a VPS a Droplet | Click "Deploy / DigitalOcean". |
| 1:10 | Need about 4 GB memory | Show the Droplet form and/or selected $24/month size. |
| 1:26 | Choose the region your server lives in | Show the region controls if reachable. |
| 1:35 | Why not home computer? | Hold on the Droplet setup UI. |
| 1:57 | Wrap-up | Stay on the setup form; no droplet creation. |

## Current Commands

Run dry rehearsals without Screen Studio:

```bash
video-scripts/03-what-is-a-vps-keeper.sh
```

Run the Screen Studio keeper after two dry rehearsals pass:

```bash
video-scripts/03-what-is-a-vps-record.sh
```

Create a timestamp-based contact sheet after a take:

```bash
video-scripts/03-what-is-a-vps-check-frames.sh \
  "$HOME/Screen Studio Projects/Built-in Retina Display YYYY-MM-DD HH:MM:SS.screenstudio" \
  0 12 24 36 48 60 72 84 96 108 122 128
```

## Working Coordinates

Coordinates assume the built-in Retina display and Helium placed by Breeze at
`184,50,1142,813`. Re-discover them if the display or window position changes.

| Target | `cliclick` coordinate | Expected state |
| --- | --- | --- |
| Helium after Breeze | `184,50,1142,813` | Standard recording position. |
| Screen Studio display picker | `m:420,905 c:.` | Built-in Retina Display is selected. |
| Screen Studio start recording | `m:757,547 c:.` | Picker starts display recording and hides itself. |
| DigitalOcean page focus | `m:1200,650 c:.` | Page receives focus without opening a link. |
| Paperless Ag deploy badge | `m:573,544 c:.` | DigitalOcean Droplet form opens in the same Helium window if already logged in. |
| DigitalOcean form focus | `m:1250,520 c:.` | Safe white form body receives focus above the sticky Total cost footer. |

## Dry Run Log

- 2026-04-28: audio measured at `129.335147` seconds.
- 2026-04-28: transcript generated with local `whisper-cli` after converting
  the m4a to `/tmp/03-what-is-a-vps.wav`.
- 2026-04-28: DigitalOcean VPS hosting page responds and opens in Helium.
- 2026-04-28: updated the screencast skill to note that the active Screen
  Studio "Start Recording" picker does not need to be hidden before starting.
- 2026-04-28: Paperless Ag page exposes a DigitalOcean deploy link to
  `https://cloud.digitalocean.com/droplets/new?size=s-2vcpu-4gb&image=docker-20-04&region=nyc1`.
- 2026-04-28: deploy badge coordinate `m:573,544 c:.` works, but Helium is not
  currently logged into DigitalOcean; the click lands on
  `cloud.digitalocean.com/login?...redirect_url=.../droplets/new...`.
- 2026-04-28 17:12 CDT: user signed into DigitalOcean in Helium; the deploy
  flow now reaches
  `https://cloud.digitalocean.com/droplets/new?size=s-2vcpu-4gb&image=docker-20-04&region=nyc1...`.
- 2026-04-28: the active Screen Studio picker presents accessibility windows
  named `Screen Studio`, `Start Recording`, an empty dialog, and
  `recording-manager-widget`; these are allowed during preflight because the
  picker hides itself when recording starts.
- 2026-04-28: do not click the sticky Total cost footer on the create Droplet
  page. Use `m:1250,520 c:.` in the white form body before any form scrolling.
- 2026-04-28: second dry run passed and ended on the Droplet form without
  hitting the Total cost footer. The final hold was lengthened so the raw take
  better matches the `129.335147` second narration.
- 2026-04-28: the Record menu and `Command+Option+3` only opened/configured the
  Screen Studio picker. Clicking the purple Start recording button at
  `m:757,547 c:.` created a successful 3.728333-second smoke capture:
  `~/Screen Studio Projects/Built-in Retina Display 2026-04-28 17:45:58.screenstudio`.
- 2026-04-28: failed take saved at
  `~/Screen Studio Projects/Built-in Retina Display 2026-04-28 17:49:43.screenstudio`
  with a `73.430000` second display track. The guard rejected it because
  DigitalOcean returned to the login page instead of the Droplet form.
- 2026-04-28: do not quit Helium during keeper preflight for this video; keep
  the running browser session warm so DigitalOcean's signed-in state survives.
- 2026-04-28: completed take saved at
  `~/Screen Studio Projects/Built-in Retina Display 2026-04-28 17:55:07.screenstudio`
  with a `122.135000` second display track. Frame review looked visually clean,
  but the take is not a keeper because it is about `7.2` seconds short versus
  the `129.335147` second narration. Final hold increased by 9 seconds.
- 2026-04-28: keeper take saved at
  `~/Screen Studio Projects/Built-in Retina Display 2026-04-28 18:02:31.screenstudio`
  and copied to `video-scripts/03-what-is-a-vps.screenstudio`. Display track
  duration is `131.196667` seconds, about `1.861520` seconds longer than the
  narration.
- 2026-04-28: keeper frame review ran:
  `video-scripts/03-what-is-a-vps-check-frames.sh "$HOME/Screen Studio Projects/Built-in Retina Display 2026-04-28 18:02:31.screenstudio" 0 12 24 36 48 60 72 84 96 108 122 130`.
  Contact sheet:
  `/var/folders/2y/r9pn89zx3dl8d44r6vylzffr0000gn/T//paperless-ag-frame-check-Built-in-Retina-Display-2026-04-28-18-02-31.jpg`.
  Review passed: no Codex or Screen Studio windows in the sampled frames, no
  DigitalOcean login bounce, no address-bar suggestions, and the take ends on
  the Droplet form without creating a Droplet.
- 2026-04-28: resulting Screen Studio project windows were minimized after the
  keeper.
