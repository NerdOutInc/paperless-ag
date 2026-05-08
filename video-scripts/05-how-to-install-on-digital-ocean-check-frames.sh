#!/usr/bin/env bash
set -euo pipefail

PROJECT="${1:?Usage: $0 /path/to/project.screenstudio}"
TRACK="$PROJECT/recording/channel-1-display-0.mp4"
OUT="${2:-/tmp/05-how-to-install-on-digital-ocean-contact-sheet.jpg}"
FRAME_DIR="${3:-/tmp/05-how-to-install-on-digital-ocean-contact-frames}"

rm -rf "$FRAME_DIR"
mkdir -p "$FRAME_DIR"

ffprobe \
  -v error \
  -show_entries format=duration \
  -of default=nk=1:nw=1 \
  "$TRACK"

for t in 0 20 40 60 90 120 150 180 210 240 270 300; do
  ffmpeg \
    -y \
    -ss "$t" \
    -i "$TRACK" \
    -frames:v 1 \
    -q:v 2 \
    "$FRAME_DIR/frame-$t.jpg" >/dev/null 2>&1 || true
done

FILTER='scale=302:196:force_original_aspect_ratio=decrease'
FILTER="${FILTER},pad=302:196:(ow-iw)/2:(oh-ih)/2,tile=4x3"

ffmpeg \
  -y \
  -framerate 1 \
  -pattern_type glob \
  -i "$FRAME_DIR/frame-*.jpg" \
  -vf "$FILTER" \
  -frames:v 1 \
  "$OUT"

echo "$OUT"
