#!/usr/bin/env bash
set -euo pipefail

socket="${KITTY_CONTROL_SOCKET:-unix:/tmp/kitty-elliot}"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
session_file="$config_dir/sessions/cangjie.conf"

focus_tab() {
  local title="$1"
  kitty @ --to "$socket" focus-tab --match "title:^${title}$" >/dev/null 2>&1
}

ensure_tab() {
  local title="$1"
  local cwd="$2"

  if focus_tab "$title"; then
    return 0
  fi

  kitty @ --to "$socket" launch \
    --type=tab \
    --cwd="$cwd" \
    --tab-title="$title" \
    zsh -l >/dev/null
}

if ! kitty @ --to "$socket" ls >/dev/null 2>&1; then
  exec "$config_dir/scripts/launch.sh" --session "$session_file"
fi

ensure_tab runtime /home/elliot/Code/working/cangjie_runtime/stdlib
ensure_tab stdx /home/elliot/Code/working/cangjie_stdx
focus_tab runtime || true
