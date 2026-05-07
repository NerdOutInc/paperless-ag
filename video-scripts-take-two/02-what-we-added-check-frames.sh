#!/usr/bin/env bash
set -euo pipefail

PROJECT="${1:-$HOME/Screen Studio Projects/Built-in Retina Display 2026-05-06 22:03:37.screenstudio}"
TRACK="$PROJECT/recording/channel-1-display-0.mp4"
OUT="${2:-/tmp/02-retake2-check-frames.jpg}"
FRAME_DIR="${3:-/tmp/02-retake2-check-frames-dir}"

if [[ ! -f "$TRACK" ]]; then
  echo "missing display track: $TRACK" >&2
  exit 1
fi

duration="$(
  ffprobe \
    -v error \
    -show_entries format=duration \
    -of default=nk=1:nw=1 \
    "$TRACK"
)"

echo "project: $PROJECT"
echo "track: $TRACK"
echo "duration: ${duration}s"
echo "contact sheet: $OUT"

rm -rf "$FRAME_DIR"
mkdir -p "$FRAME_DIR"

timestamps=(0 8 18 32 48 66 88 112 136 160 184 206)
index=0
for t in "${timestamps[@]}"; do
  printf -v frame "%s/frame-%02d-%03d.jpg" "$FRAME_DIR" "$index" "$t"
  ffmpeg \
    -y \
    -ss "$t" \
    -i "$TRACK" \
    -frames:v 1 \
    -q:v 2 \
    "$frame" >/dev/null 2>&1
  index=$((index + 1))
done

filter='scale=454:294:force_original_aspect_ratio=decrease'
filter="${filter},pad=454:294:(ow-iw)/2:(oh-ih)/2,tile=4x3"

ffmpeg \
  -y \
  -framerate 1 \
  -pattern_type glob \
  -i "$FRAME_DIR/frame-*.jpg" \
  -vf "$filter" \
  -frames:v 1 \
  "$OUT" >/dev/null 2>&1

echo "$OUT"
