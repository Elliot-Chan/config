#!/usr/bin/env bash

set -euo pipefail

# Format:
#   user:unit:label[:process]
#   system:unit:label[:process]
#   script:path:label
# The optional process is a lightweight fallback for environments where
# systemd's bus is not reachable.
DEFAULT_SERVICES=(
  "user:swaync.service:swaync:swaync"
  "user:waybar.service:waybar:waybar"
  "system:mihomo.service:mihomo:mihomo"
  "script:$HOME/.config/waybar/scripts/ai_usage_refresh_status.sh:ai-refresh"
)

read_services() {
  if [[ -n "${WAYBAR_SERVICE_STATUS_UNITS:-}" ]]; then
    tr ',' '\n' <<<"$WAYBAR_SERVICE_STATUS_UNITS"
    return
  fi

  printf '%s\n' "${DEFAULT_SERVICES[@]}"
}

is_active() {
  local scope=$1
  local unit=$2
  local process=${3:-}

  case "$scope" in
    user)
      systemctl --user is-active --quiet "$unit" 2>/dev/null && return 0
      ;;
    system)
      systemctl is-active --quiet "$unit" 2>/dev/null && return 0
      ;;
    script)
      "$unit" >/dev/null 2>&1 && return 0
      ;;
    *)
      return 1
      ;;
  esac

  [[ -n "$process" ]] && pgrep -x "$process" >/dev/null 2>&1
}

main() {
  local total=0
  local active=0
  local text=""
  local tooltip=""
  local spec scope unit label process state light

  while IFS= read -r spec; do
    [[ -z "$spec" ]] && continue
    IFS=: read -r scope unit label process <<<"$spec"
    [[ -z "${scope:-}" || -z "${unit:-}" ]] && continue
    label=${label:-$unit}
    process=${process:-}
    total=$((total + 1))

    if is_active "$scope" "$unit" "$process"; then
      state="up"
      light="<span color='#a6e3a1'>●</span>"
      active=$((active + 1))
    else
      state="down"
      light="<span color='#f38ba8'>●</span>"
    fi

    text+="${text:+ }$light"
    tooltip+="${label}: ${state}"$'\n'
  done < <(read_services)

  local class="critical"
  if (( total == 0 )); then
    class="unknown"
  elif (( active == total )); then
    class="ok"
  elif (( active > 0 )); then
    class="warn"
  fi

  jq -cn \
    --arg text "$text" \
    --arg tooltip "services: ${active}/${total}"$'\n'"${tooltip%$'\n'}" \
    --arg class "$class" \
    '{text: $text, tooltip: $tooltip, class: $class}'
}

main
