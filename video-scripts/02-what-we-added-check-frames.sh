#!/usr/bin/env bash
set -euo pipefail

PROJECT="${1:-}"

if [[ -z "$PROJECT" ]]; then
  PROJECT="$(ls -td "$HOME/Screen Studio Projects"/*.screenstudio 2>/dev/null | head -1 || true)"
fi

if [[ -z "$PROJECT" ]]; then
  echo "Usage: $0 /path/to/project.screenstudio [timestamp ...]" >&2
  echo "No Screen Studio project was supplied and none were found." >&2
  exit 2
fi

shift || true

TRACK="$PROJECT/recording/channel-1-display-0.mp4"
if [[ ! -f "$TRACK" ]]; then
  echo "Display track not found: $TRACK" >&2
  exit 3
fi

DURATION="$(ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 "$TRACK")"
PROJECT_SLUG="$(basename "$PROJECT" .screenstudio | tr ' /:' '---' | tr -cd '[:alnum:]_.-')"
FRAME_DIR="${TMPDIR:-/tmp}/paperless-ag-frame-check-$PROJECT_SLUG"
OUT="${TMPDIR:-/tmp}/paperless-ag-frame-check-$PROJECT_SLUG.jpg"

rm -rf "$FRAME_DIR"
mkdir -p "$FRAME_DIR"

if [[ "$#" -gt 0 ]]; then
  TIMES=("$@")
else
  mapfile -t TIMES < <(
    awk -v duration="$DURATION" 'BEGIN {
      count = 11
      last = duration - 2
      if (last < 0) {
        last = duration
      }
      for (i = 0; i < count; i++) {
        printf "%.0f\n", (last * i) / (count - 1)
      }
    }'
  )
fi

printf 'project=%s\n' "$PROJECT"
printf 'track=%s\n' "$TRACK"
printf 'duration=%s\n' "$DURATION"
printf 'timestamps=%s\n' "${TIMES[*]}"

for i in "${!TIMES[@]}"; do
  t="${TIMES[$i]}"
  frame="$FRAME_DIR/frame-$(printf '%02d' "$i")-${t}s.jpg"
  ffmpeg -y -ss "$t" -i "$TRACK" -frames:v 1 -q:v 2 "$frame" >/dev/null 2>&1
done

ffmpeg -y \
  -framerate 1 \
  -pattern_type glob \
  -i "$FRAME_DIR/frame-*.jpg" \
  -vf "scale=302:196:force_original_aspect_ratio=decrease,pad=302:196:(ow-iw)/2:(oh-ih)/2,tile=4x3:padding=0:margin=0" \
  -frames:v 1 \
  "$OUT" >/dev/null 2>&1

printf 'frames=%s\n' "$FRAME_DIR"
printf 'contact_sheet=%s\n' "$OUT"
