# 05 - How To Install On DigitalOcean - Screencast Actions

Source audio: `garage-band/05-how-to-install-on-digital-ocean.m4a`
Working audio copy: `video-scripts/05-how-to-install-on-digital-ocean.m4a`
Duration: `267.540317` seconds

Transcript note: Whisper hears "Fullstack Egg", "Paperless Egg", "Papeless",
and "Cloud". Production notes should read "Fullstack Ag", "Paperless Ag",
"Paperless", and "Claude".

Plan status: user approved creating one real DigitalOcean droplet for the
keeper recording only. Rehearsals must not click `Create Droplet`.

## Story Beats

- 0:00-0:19: Start on `paperless.fullstack.ag`. Introduce installing
  Paperless NGX plus Paperless Ag onto a DigitalOcean droplet and promise a
  working AI-searchable document archive.
- 0:19-0:37: Click the site's `Deploy to DigitalOcean` button. Mention that
  the button only sets defaults and a droplet can also be created manually.
- 0:37-0:52: On the DigitalOcean Create Droplet page, scroll past region and
  show the selected Ubuntu image, Basic droplet, regular CPU, and 4 GB memory.
- 0:52-1:17: Show authentication with an existing SSH key. Briefly show the
  `Add SSH Key` affordance, but do not generate or expose private key material.
- 1:17-1:32: Name the droplet `paperless-video`, show the approximately
  `$24/month` cost, and click `Create Droplet` only after explicit approval.
- 1:32-1:42: Fast-forward the droplet creation wait. Show the finished droplet
  and copy its public IP address.
- 1:42-2:06: Open Terminal, run `ssh root@<droplet-ip>`, accept the host
  fingerprint if prompted, and show a successful root shell on the server.
- 2:06-2:20: Return to `paperless.fullstack.ag`, copy the install script, then
  go back to the SSH session.
- 2:20-2:47: Paste and run the install script. Answer prompts: use the default
  install directory, choose a demo Paperless username and password, and skip the
  domain prompt unless the user wants a real domain included.
- 2:47-3:07: Fast-forward the install wait. Hold on the completed output that
  shows the Paperless URL and Claude connection details.
- 3:07-3:20: Open the browser to the URL printed by the installer, currently
  `http://<droplet-ip>` because Caddy proxies Paperless on port 80. Log in
  with the demo credentials and show the Paperless document UI running.
- 3:20-3:36: Drag a safe sample PDF into the browser. Wait while Paperless
  processes it and explain that Paperless Ag picks it up automatically.
- 3:36-4:27: End on the working Paperless archive. The narration points viewers
  to the Paperless Ag/Claude video and the upcoming Raspberry Pi install video.

## Planned Capture

- Capture scope: full display.
- Target apps: Helium for browser work, Terminal for SSH/install, Screen Studio
  for full-display capture.
- Browser starting state: Helium on `https://paperless.fullstack.ag`, with
  DigitalOcean already signed in before any recording attempt.
- Terminal starting state: local shell ready, no sensitive unrelated output in
  the visible scrollback.
- On-camera sample upload: use a fictional/test PDF from this repo, not a
  personal document. User placed `001_soil_test_north_quarter_section_12.pdf`
  on the Desktop for the keeper upload demo.
- Final state: Paperless running on the new droplet at the installer-printed
  URL, currently `http://<droplet-ip>`, with at least one uploaded PDF visible.

## Setup And Reset Steps

- Start the Screen Studio status server before any dry runs, share the PIN,
  Bonjour URL, LAN URL, and QR code in chat, then wait 20 seconds.
- Confirm Helium, Terminal, `cliclick`, `ffmpeg`, and `ffprobe` are available.
- Confirm the DigitalOcean account is logged in and has the intended SSH key
  available.
- Create exactly one real DigitalOcean droplet total, and only during the
  keeper take. If the keeper fails, do not create another droplet.
- Do not destroy any DigitalOcean droplets.
- Use a disposable droplet name `paperless-video` and demo credentials only.
- Minimize old Screen Studio project and recording windows before the keeper
  take.
- Hide Codex and unrelated workbench apps before the keeper take.
- Do not resize or reposition Helium or Terminal after coordinate calibration.
- Clear Terminal before the smoke capture and keeper recording.
- Reset DigitalOcean rehearsals by navigating Helium back to
  `https://paperless.fullstack.ag`, not by creating or destroying resources.
- If Screen Studio's keyboard recording flow is unproven in the current state,
  make and verify a 3-5 second smoke capture before the keeper.
- After real provisioning/install work, leave the DigitalOcean droplet running.

## Coordinates And Helper Commands

- Helium window: `185,50,1141,840`. Do not resize or reposition it after
  calibration.
- Desktop PDF source:
  `/Users/brian/Desktop/001_soil_test_north_quarter_section_12.pdf`.
- Finder Desktop PDF position: `{1425, 174}`.
- PDF drag path for Paperless upload:
  `dd:1423,261 dm:1340,260 dm:1200,310 dm:1000,380 dm:820,470 du:820,470`.
- Paperless install page deploy button:
  `cliclick -e 300 m:586,544 c:.`
- DigitalOcean form focus point before scrolls:
  `cliclick -e 250 m:1000,650 c:.`
- Smooth scroll helper:

  ```bash
  /Users/brian/github/nerdoutinc/ai-skills/screen-studio/scripts/scroll-wheel.swift \
    trackpad 2 down 0.04 0.20 "12,24,42,66,90,66,42,24,12"
  ```

- From the DigitalOcean top, the keeper should use slow trackpad bursts:
  show region, then image and plan defaults, then SSH authentication.
- Brian SSH key checkbox:
  `cliclick -e 350 m:589,441 c:.`
- From SSH keys to droplet name:

  ```bash
  /Users/brian/github/nerdoutinc/ai-skills/screen-studio/scripts/scroll-wheel.swift \
    trackpad 2 down 0.04 0.20 "12,24,42,66,90,66,42,24,12"
  /Users/brian/github/nerdoutinc/ai-skills/screen-studio/scripts/scroll-wheel.swift \
    trackpad 1 down 0.04 0.20 "8,16,28,42,56,42,28,16,8"
  ```

- Droplet name field:
  `cliclick -e 300 m:820,506 c:.`
- Droplet name text: `paperless-video`.
- Create button coordinate, keeper only:
  `cliclick -e 350 m:862,839 c:.`
- DigitalOcean visible account name during rehearsal: `Nick`.
- DigitalOcean selected key: `Brian Pattison's MacBook Pro`.
- DigitalOcean cost during rehearsal: `$24.00/month`, `$0.036/hour`.

## Keeper Install Inputs

- SSH command: `ssh root@<droplet-ip>`.
- Installer command:
  `curl -fsSL https://paperless.fullstack.ag/install.sh | bash`.
- Use Terminal AppleScript `do script` for the recorded SSH command, installer
  command, and prompt answers. Direct simulated typing/paste into Terminal was
  unreliable, but `do script` was proven with `echo Hello World`, `which ssh`,
  a typed prompt answer, and blank Enter.
- Fresh install prompt order:
  admin username, hidden admin password and confirmation, timezone choice,
  domain, install directory.
- Use username `admin`.
- Use password `PaperlessAg2026`.
- Choose timezone default `1` for `America/Chicago`.
- Press Enter to skip domain.
- Press Enter for the default install directory.
- If an SSH host fingerprint prompt appears, type `yes`.
- If Docker unexpectedly is not installed, accept the install prompt and wait.
- The current installer exposes Paperless via Caddy on `http://<droplet-ip>`,
  not direct `:8000`.

## Dry Run Plan

- Discovery run: verify the live DigitalOcean page flow, find stable
  coordinates, identify any prompts or first-time dialogs, and rehearse the
  browser/terminal transitions. Do not click `Create Droplet`.
- Validation run: repeat the planned DigitalOcean navigation without pressing
  `Create Droplet`, and separately practice dragging the Desktop PDF into the
  local Paperless instance at `http://localhost:8000`.
- Notes are checked and surfaced between dry runs through the status server.
- No keeper recording begins until two dry runs pass.

## State Checks

- `paperless.fullstack.ag` loads and the deploy/install-script sections are
  reachable.
- DigitalOcean account is signed in and shows the expected SSH key.
- The selected plan visibly matches the narration, or any live UI difference is
  documented before recording.
- Droplet IP is copied from the correct droplet.
- SSH reaches the new droplet as `root`.
- Install script completes successfully and prints the Paperless URL.
- The installer-printed URL, currently `http://<droplet-ip>`, loads the
  Paperless login page.
- Demo credentials log into Paperless successfully.
- PDF upload starts and produces a visible document in the archive.
- Post-take Screen Studio verification checks the display track with `ffprobe`
  and inspects a timestamp contact sheet before calling the take a keeper.

## Keeper Defaults

- Use temporary demo Paperless credentials selected by Codex for the recording.
- Skip the domain prompt and access Paperless by IP address, matching the
  narration.

## Dry Run Log

- 2026-05-07: Audio transcribed locally with `whisper-cli`; transcript cues
  above were drafted from the audio.
- 2026-05-07: Plan drafted from audio only. No dry runs or recordings started.
- 2026-05-07: User approved one real DigitalOcean droplet for the keeper take
  only. Rehearsals must not create a droplet, no droplet should ever be
  destroyed, and the Desktop PDF
  `001_soil_test_north_quarter_section_12.pdf` should be used for the upload
  demo. User is logged into DigitalOcean.
- 2026-05-06 local evening: Status server is running at PIN `9301`, with
  Bonjour URL `http://Brians-MacBook-Pro.local:8765/?pin=9301` and LAN URL
  `http://192.168.68.75:8765/?pin=9301`.
- 2026-05-06 local evening: DigitalOcean discovery verified the prefilled
  create page. Defaults visible: Ubuntu Docker image, Basic, regular CPU,
  4 GB memory, NYC region, and `$24.00/month` cost. No droplet was created.
- 2026-05-06 local evening: User notes asked to match scroll positions to
  narration, record scroll choreography here, select Brian's SSH key as the
  example action, clear Terminal before recordings, and reset DigitalOcean by
  navigating back to the Paperless Ag webpage.
- 2026-05-06 local evening: Local Paperless drag/drop rehearsal first failed
  because the same PDF already existed. Document id `1` was moved to trash and
  then permanently emptied from the local test instance only.
- 2026-05-06 local evening: Final local drag/drop rehearsal succeeded. Local
  Paperless returned to `100` documents, with uploaded document id `142` and
  original file name `001_soil_test_north_quarter_section_12.pdf`.
- 2026-05-06 local evening: Slow DigitalOcean validation selected only
  `Brian Pattison's MacBook Pro`, scrolled to the droplet name, typed
  `paperless-video`, and stopped with the enabled `Create Droplet` button
  visible but unclicked.
- 2026-05-07 00:00 local: A keeper attempt was started, then rejected before
  any droplet was created. Reason: the previous Screen Studio project window
  was still visible behind Helium in the full-display capture.
- 2026-05-07 00:08 local: Rejected attempt verified with display track duration
  `252.556667` seconds. Contact sheet:
  `video-scripts/05-how-to-install-on-digital-ocean-aborted-contact-sheet.jpg`.
  DigitalOcean never passed the safe create-page preview; `Create Droplet` was
  not clicked.
- 2026-05-07 07:47 local: A long keeper attempt was started from a clean
  Paperless Ag page. The DigitalOcean create page was corrected back to the
  intended 4 GB plan before provisioning.
- 2026-05-07 08:14 local: The single approved real DigitalOcean droplet was
  created. One-droplet budget is now spent; do not create another droplet.
  Droplet details visible in DigitalOcean: `paperless-video`, id `569558948`,
  public IPv4 `174.138.57.126`, NYC3, Ubuntu 24.04 LTS x64, `$24.00/month`,
  with `Brian Pattison's MacBook Pro` selected as the SSH key.
- 2026-05-07 08:40 local: User stopped the recording before SSH/install could
  be completed. Terminal automation hit a macOS permission prompt and then
  timed out; no install script was run. Do not destroy the droplet.
- 2026-05-07 09:42 local: Terminal input rehearsal switched to AppleScript
  `do script`, which reliably ran `echo Hello World`, `which ssh`, answered a
  fake prompt, and sent a blank Enter. Off-camera SSH connectivity to
  `174.138.57.126` succeeded and the host key is already accepted.
- 2026-05-07 09:42 local: Non-mutating droplet state check found a fresh
  server: `/root/paperless-ag` missing, Docker missing, and nothing listening
  on port 80. The recorded installer should show Docker installation.
- 2026-05-07 09:44 local: Started the continuation recording from a clean
  Terminal using Screen Studio's full-display keyboard flow. SSH to
  `174.138.57.126` succeeded, the installer ran, Docker was installed, fresh
  Paperless credentials were configured, and the installer completed with
  Paperless available at `http://174.138.57.126`.
- 2026-05-07 09:57 local: Continuation recording stopped after opening the
  remote Paperless Documents archive. Login worked with the demo credentials,
  the Desktop PDF uploaded successfully, and the final frame shows one visible
  document card for `001_soil_test_north_quarter_section_12`.
- 2026-05-07 10:49 local: The `09:44` continuation recording was accidentally
  deleted while stale Screen Studio windows were being closed. User restored
  the droplet base image and reset the app state.
- 2026-05-07 10:56 local: Started the continuation retake from Terminal after
  removing the local known-host entry for `174.138.57.126`. The recording shows
  the first SSH connection authenticity prompt and the typed `yes` acceptance
  before the installer is run.
- 2026-05-07 11:18 local: Continuation retake stopped after the installer,
  remote Paperless login, Desktop PDF upload, and final Documents archive view.
  The final frame shows one document, with
  `001_soil_test_north_quarter_section_12` visible.

## Keeper Recording

- Screen Studio project folder:
  `/Users/brian/Screen Studio Projects/`
- Rejected attempt project:
  `/Users/brian/Screen Studio Projects/Built-in Retina Display 2026-05-07 00:00:14.screenstudio`
- Rejected attempt display track duration: `252.556667` seconds.
- Audio duration: `267.540317` seconds.
- Versioned rejected contact sheet:
  `video-scripts/05-how-to-install-on-digital-ocean-aborted-contact-sheet.jpg`
- Review frames: rejected because stale Screen Studio project UI was visible.
- Stopped long attempt project:
  `/Users/brian/Screen Studio Projects/05-long-keeper.screenstudio`
- Stopped long attempt display track duration: `3179.091667` seconds.
- Stopped long attempt status: not a keeper; user stopped before SSH/install.
- Deleted continuation project:
  `/Users/brian/Screen Studio Projects/Built-in Retina Display 2026-05-07 09:44:15.screenstudio`
- Deleted continuation display track duration: `812.818333` seconds.
- Deleted continuation contact sheet:
  `video-scripts/05-how-to-install-on-digital-ocean-continuation-contact-sheet.jpg`
- Deleted continuation frame review: passed before deletion. The sampled frames
  showed the clean Terminal start, SSH session, installer prompt sequence,
  Docker/image waits, installer success output, Paperless login, PDF upload,
  and final Documents archive with the uploaded soil test visible.
- Continuation retake keeper project:
  `/Users/brian/Screen Studio Projects/Built-in Retina Display 2026-05-07 10:56:22.screenstudio`
- Continuation retake safety copy:
  `/Users/brian/Screen Studio Projects/05-continuation-retake-keeper.screenstudio`
- Continuation retake display track duration: `1310.106667` seconds.
- Continuation retake contact sheet:
  `video-scripts/05-how-to-install-on-digital-ocean-retake-contact-sheet.jpg`
- Continuation retake frame review: passes. The sampled frames show the
  first-SSH unknown-host prompt, the `yes` acceptance, successful root login,
  Docker/install prompt sequence, installer success output, Paperless login,
  PDF upload, and final Documents archive with the uploaded soil test visible.
- Status-page notes during continuation take: none new.
- Keeper project: use the previous droplet-creation footage stitched with the
  continuation retake keeper project in post.
