#!/usr/bin/env bash

set -euo pipefail

tool="${1:-}"
target_dir="${2:-$PWD}"

if [[ ! -d "$target_dir" ]]; then
  target_dir=$(dirname "$target_dir")
fi

case "$tool" in
  wezterm)
    if command -v wezterm >/dev/null 2>&1; then
      exec wezterm start --cwd "$target_dir"
    fi
    ;;
  nvim)
    if command -v wezterm >/dev/null 2>&1; then
      exec wezterm start --cwd "$target_dir" zsh -lc 'nvim .'
    elif command -v kitty >/dev/null 2>&1; then
      exec kitty --directory "$target_dir" zsh -lc 'nvim .'
    fi
    ;;
esac

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Yazi" "Unable to open ${tool} in ${target_dir}"
fi
exit 1
