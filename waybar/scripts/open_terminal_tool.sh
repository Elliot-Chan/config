#!/usr/bin/env bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "usage: $0 <command> [args...]" >&2
  exit 1
fi

if command -v wezterm >/dev/null 2>&1; then
  exec wezterm start --always-new-process -- "$@"
fi

if command -v kitty >/dev/null 2>&1; then
  exec kitty --detach "$@"
fi

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Waybar" "No supported terminal found for: $*"
fi

exit 1
