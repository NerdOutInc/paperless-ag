# Docker HyperFrames Timing Notes

## Segment Map

| Output Time | Visual |
| --- | --- |
| `00:00-00:04.2` | Original static Fullstack AG title card |
| `00:03.1-00:11.8` | Docker appears during setup; plain packaging definition |
| `00:11.0-00:27.4` | Shipping-container metaphor for software |
| `00:26.8-00:47.3` | Services and dependencies in predictable containers |
| `00:46.8-01:26.1` | Preserved Docker Desktop + Terminal `docker ps` footage |
| `01:25.6-01:38.4` | Containers can be replaced; data lives separately |
| `01:37.5-01:48.7` | Docker in a nutshell: same bundle, same commands |
| `01:48.1-01:56.9` | Setup script handles the Docker work |
| `01:55.9-02:00.37` | Original static Fullstack AG outro card |

## Splice

- HyperFrames slides render:
  `videos/04-what-is-docker-build/04-what-is-docker-hyperframes-slides.mp4`
- Source video:
  `videos/04-what-is-docker.mp4`
- Review candidate:
  `videos/04-what-is-docker-hyperframes-preview.mp4`
- The candidate keeps the original video's audio stream unchanged.
- The real Docker Desktop/Terminal footage starts from source `00:47.6` so the
  handoff lands on the clean Docker Desktop app instead of the stale Docker
  website frame.
- The demo splice ends on readable Terminal output before the second Docker
  Desktop fill hold. A `0.9s` hold on that Terminal output pads the skipped
  browser frames and avoids the second Docker Desktop filler shot while keeping
  later slides aligned with the narration.
- Visual crossfades last `0.5s` at both handoffs. The first handoff now holds
  the dependency/package slide instead of using a separate bridge slide.

## Render-Time Mapping

The HyperFrames composition is shorter than the final video because the real
demo section comes from the finished MP4:

- Render `00:00-00:47.3` maps to final `00:00-00:47.3`.
- Render `00:47.3-01:22.07` maps to final `01:25.6-02:00.37`.

## Review Frames

The review contact sheet is generated from:

- `00:00.5`
- `00:04`
- `00:08`
- `00:10.8`
- `00:11.2`
- `00:18`
- `00:32`
- `00:44`
- `00:46.8`
- `00:47.1`
- `00:48`
- `01:04`
- `01:25.8`
- `01:26.3`
- `01:58`
