#!/usr/bin/env bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "usage: $0 <command> [args...]" >&2
  exit 1
fi

ghostty_launcher="${GHOSTTY_LAUNCHER:-$HOME/config/ghostty/scripts/launch.sh}"
if [[ -x "$ghostty_launcher" ]]; then
  exec "$ghostty_launcher" "$@"
fi

kitty_launcher="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/scripts/launch.sh"
if [[ -x "$kitty_launcher" ]]; then
  exec "$kitty_launcher" --detach "$@"
fi

if command -v kitty >/dev/null 2>&1; then
  LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}" exec kitty --detach "$@"
fi

if command -v wezterm >/dev/null 2>&1; then
  exec wezterm start --always-new-process -- "$@"
fi

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Waybar" "No supported terminal found for: $*"
fi

exit 1
