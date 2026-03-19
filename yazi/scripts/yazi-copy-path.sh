#!/usr/bin/env bash

set -euo pipefail

mode="${1:-abs}"
target="${2:-}"

if [[ -z "$target" ]]; then
  echo "missing target path" >&2
  exit 1
fi

if [[ "$mode" == "rel" ]]; then
  value=$(realpath --relative-to="$PWD" "$target")
else
  value=$(realpath "$target")
fi

printf '%s' "$value" | wl-copy
if command -v notify-send >/dev/null 2>&1; then
  notify-send "Yazi" "Copied ${mode} path: ${value}"
fi
