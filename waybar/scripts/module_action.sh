#!/usr/bin/env bash

set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
WEATHER_MODE_FILE="${CACHE_DIR}/weather.mode"
NETWORK_MODE_FILE="${CACHE_DIR}/network.mode"

notify() {
  local title=$1
  local body=$2
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$body"
  fi
}

refresh_signal() {
  local signal=$1
  pkill "-RTMIN+${signal}" waybar
}

ensure_cache_dir() {
  mkdir -p "$CACHE_DIR"
}

copy_and_notify() {
  local label=$1
  local value=$2
  if [[ -z "$value" ]]; then
    notify "Waybar" "No ${label} available"
    return 1
  fi

  printf '%s' "$value" | wl-copy
  notify "Waybar" "Copied ${label}: ${value}"
}

pick_interface() {
  local default_if
  default_if=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
  if [[ -n "$default_if" ]]; then
    printf '%s\n' "$default_if"
    return
  fi

  local iface
  for iface in /sys/class/net/*; do
    iface=${iface##*/}
    [[ "$iface" == "lo" ]] && continue
    printf '%s\n' "$iface"
    return
  done
}

cycle_mode() {
  local file=$1
  local current=$2
  shift 2
  local modes=("$@")
  local next="${modes[0]}"
  local i

  for ((i = 0; i < ${#modes[@]}; i++)); do
    if [[ "${modes[i]}" == "$current" ]]; then
      next="${modes[((i + 1) % ${#modes[@]})]}"
      break
    fi
  done

  printf '%s' "$next" > "$file"
  printf '%s' "$next"
}

run_weather_json() {
  zsh -lc '[[ -f ~/.custom.zsh ]] && source ~/.custom.zsh; python3 ~/.config/waybar/scripts/weather.py'
}

action_weather_refresh() {
  refresh_signal 8
  notify "Waybar" "Weather refresh requested"
}

action_weather_toggle_mode() {
  ensure_cache_dir
  current_mode=$(cat "$WEATHER_MODE_FILE" 2>/dev/null || echo "temp")
  next_mode=$(cycle_mode "$WEATHER_MODE_FILE" "$current_mode" temp text)
  refresh_signal 8
  notify "Waybar" "Weather mode: ${next_mode}"
}

action_weather_copy() {
  weather_text=$(run_weather_json | jq -r '.text')
  copy_and_notify "weather" "$weather_text"
}

action_network_copy_ip() {
  ip_addr=$(ip -4 addr show up scope global | awk '/inet / {print $2; exit}' | cut -d/ -f1)
  copy_and_notify "IPv4" "$ip_addr"
}

action_network_copy_iface() {
  iface=$(pick_interface)
  copy_and_notify "interface" "$iface"
}

action_network_toggle_mode() {
  ensure_cache_dir
  current_mode=$(cat "$NETWORK_MODE_FILE" 2>/dev/null || echo "rate")
  next_mode=$(cycle_mode "$NETWORK_MODE_FILE" "$current_mode" rate ip iface)
  refresh_signal 9
  notify "Waybar" "Network mode: ${next_mode}"
}

case "${1:-}" in
  weather-refresh)
    action_weather_refresh
    ;;
  weather-toggle-mode)
    action_weather_toggle_mode
    ;;
  weather-copy)
    action_weather_copy
    ;;
  network-copy-ip)
    action_network_copy_ip
    ;;
  network-copy-iface)
    action_network_copy_iface
    ;;
  network-toggle-mode)
    action_network_toggle_mode
    ;;
  *)
    notify "Waybar" "Unknown action: ${1:-missing}"
    exit 1
    ;;
esac
