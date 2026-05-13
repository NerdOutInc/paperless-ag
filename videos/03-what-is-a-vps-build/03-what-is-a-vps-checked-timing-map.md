# 03 What Is a VPS Checked Timing Map

| Source time | Output time | Action / visual | Narration cue | Operation |
| --- | ---: | --- | --- | --- |
| card | 00:00.0-00:04.0 | Fullstack AG intro title card | "Hey, this is Brian..." | 4s intro, 1s crossfade |
| 0.0-27.0 | 00:03.0-00:30.0 | First browser tab, from Droplets hero to the start of the page scroll | "Before we set up paperless" through the first-tab setup context | Native video under intro fade; no pre-scroll freezes |
| 27.0-45.0 | 00:30.0-00:58.0 | First browser tab scrolling to the lower-page "Start building today" view | "rent just a slice" through "they call a VPS a droplet" lead-in | Slowed first-tab scroll; no freeze before tab switch |
| mixed 45.0-51.054373 | 00:58.0-01:03.0 | Create Droplet flow from `videos/05-how-to-install-on-digital-ocean.mp4` source 00:32-00:38.054 | "they call a VPS a droplet" | Speed-adjusted replacement footage |
| frame 01:03 | 01:03.0-01:09.0 | Datacenter-region frame from the current preview at 01:03 | Hold on region context | 6s freeze |
| mixed 51.054373-52.265247 | 01:09.0-01:10.0 | Move from datacenter region toward image selection | Transition context | Speed-adjusted replacement footage |
| frame 01:04 | 01:10.0-01:16.0 | Image-selection frame from the current preview at 01:04 | Hold on image context | 6s freeze |
| mixed 52.265247-71.639239 | 01:16.0-01:32.0 | Continue Create Droplet form before the first removed range | Droplet setup narration | Speed-adjusted replacement footage |
| mixed 71.639239-88.591482 | removed | Visual material formerly at current 01:20-01:34 | Removed by request | Visual cut |
| mixed 88.591482-97.067604 | 01:32.0-01:39.0 | Continue Create Droplet form after the first cut | Droplet setup narration | Speed-adjusted replacement footage |
| mixed 97.067604-101.911102 | removed | Visual material formerly at current 01:41-01:45 | Removed by request | Visual cut |
| mixed 101.911102-104.332851 | 01:39.0-01:41.0 | Continue toward the slowed late section | Closing setup context | Speed-adjusted replacement footage |
| mixed 104.332851-107.965474 | 01:41.0-01:50.0 | Visual material formerly at current 01:47-01:50 | Closing setup context | Slowed 3x |
| mixed 107.965474-118.0 | 01:50.0-01:58.3 | Finish the replacement Create Droplet footage | Closing lines after the audio cut | Speed-adjusted replacement footage |
| card | 01:57.3-02:01.3 | Fullstack AG outro title card | Final thanks | 4s outro, 1s crossfade |

Notes:

- The checked map uses the refreshed `videos/src/03-what-is-a-vps.mp4` from May
  13, 2026.
- The narration now uses
  `03-what-is-a-vps-audio-deblipped-01-26.m4a`, which removes the original
  01:26-01:34 line and silences isolated blips around the current-preview
  01:25 and 01:26 marks.
- The intro follows the existing series pattern: narration begins under the
  title card and the body fades in at 3 seconds.
- The first browser tab plays natively until the scroll begins at 00:30 output
  time, then the scroll is slowed to land on the second-tab switch at 00:58.
- The second browser tab switches in at 00:58 output time and is slowed to fill
  the remaining narration without frozen scrolling frames.
- The post-switch Create Droplet visual comes from
  `videos/05-how-to-install-on-digital-ocean.mp4` source 00:32-01:45, appended
  into the repo-local mixed source video.
- The former current-preview visual ranges 01:20-01:34 and 01:41-01:45 are
  skipped. The time is replaced by 6s holds on current-preview frames 01:03 and
  01:04 plus a slowed version of the former current-preview 01:47-01:50 visual.
