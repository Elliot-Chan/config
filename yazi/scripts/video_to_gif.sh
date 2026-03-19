#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <video-file>" >&2
  exit 1
fi

input=$1
output="${input%.*}.gif"

ffmpeg -y -i "$input" -vf "fps=10,scale=iw:-1:flags=lanczos" -loop 0 "$output"

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Yazi" "GIF created: ${output}"
fi
