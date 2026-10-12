#!/usr/bin/env bash
set -euo pipefail

if (( $# < 1 || $# > 3 )); then
  echo "Usage: ${0##*/} INPUT [OUTPUT.mp4] [CRF (0-51, default: 28)]" >&2
  exit 1
fi

input=$1
filename=${input##*/}
output=${2:-${input%"$filename"}${filename%.*}-compressed.mp4}
crf=${3:-28}

if [[ ! -f "$input" ]]; then
  echo "Input file not found: $input" >&2
  exit 1
fi

if [[ -e "$output" || -L "$output" ]]; then
  echo "Output already exists: $output" >&2
  exit 1
fi

if [[ ! $crf =~ ^[0-9]{1,2}$ ]] || (( 10#$crf > 51 )); then
  echo "CRF must be an integer from 0 to 51 (lower means higher quality)." >&2
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is required. Install it with: sudo pacman -S ffmpeg" >&2
  exit 1
fi

# Keep relative output names starting with '-' from becoming ffmpeg options.
[[ $output == -* ]] && output="./$output"

exec ffmpeg -hide_banner -n -i "$input" \
  -map 0:v:0 -map '0:a:0?' \
  -c:v libx264 -crf "$crf" -preset medium -pix_fmt yuv420p \
  -c:a aac -b:a 128k -movflags +faststart -f mp4 "$output"
