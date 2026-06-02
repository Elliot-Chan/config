#!/usr/bin/env bash

set -euo pipefail

tool="${1:-}"
target_dir="${2:-$PWD}"
ghostty_launcher="${GHOSTTY_LAUNCHER:-$HOME/config/ghostty/scripts/launch.sh}"
kitty_launcher="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/scripts/launch.sh"

if [[ ! -d "$target_dir" ]]; then
  target_dir=$(dirname "$target_dir")
fi

case "$tool" in
  ghostty | wezterm)
    if [[ -x "$ghostty_launcher" ]]; then
      exec "$ghostty_launcher" --directory "$target_dir"
    elif command -v wezterm >/dev/null 2>&1; then
      exec wezterm start --cwd "$target_dir"
    fi
    ;;
  nvim)
    if [[ -x "$ghostty_launcher" ]]; then
      exec "$ghostty_launcher" --directory "$target_dir" zsh -lc 'nvim .'
    elif command -v wezterm >/dev/null 2>&1; then
      exec wezterm start --cwd "$target_dir" zsh -lc 'nvim .'
    elif [[ -x "$kitty_launcher" ]]; then
      exec "$kitty_launcher" --directory "$target_dir" zsh -lc 'nvim .'
    elif command -v kitty >/dev/null 2>&1; then
      LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}" exec kitty --directory "$target_dir" zsh -lc 'nvim .'
    fi
    ;;
esac

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Yazi" "Unable to open ${tool} in ${target_dir}"
fi
exit 1
