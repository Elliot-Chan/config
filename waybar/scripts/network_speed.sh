#!/usr/bin/env bash

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
MODE_FILE="${CACHE_DIR}/network.mode"

pick_interface() {
  local default_if
  default_if=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
  if [[ -n "$default_if" && -d "/sys/class/net/$default_if" ]]; then
    printf '%s\n' "$default_if"
    return
  fi

  local iface state
  for iface in /sys/class/net/*; do
    iface=${iface##*/}
    [[ "$iface" == "lo" ]] && continue
    [[ ! -r "/sys/class/net/$iface/operstate" ]] && continue
    state=$(<"/sys/class/net/$iface/operstate")
    if [[ "$state" == "up" ]]; then
      printf '%s\n' "$iface"
      return
    fi
  done

  for iface in /sys/class/net/*; do
    iface=${iface##*/}
    [[ "$iface" == "lo" ]] && continue
    printf '%s\n' "$iface"
    return
  done
}

format_rate() {
  local bytes=$1
  if (( bytes >= 1048576 )); then
    awk -v v="$bytes" 'BEGIN { printf "%.1fMB/s", v / 1048576 }'
  elif (( bytes >= 1024 )); then
    awk -v v="$bytes" 'BEGIN { printf "%.0fKB/s", v / 1024 }'
  else
    printf '%dB/s' "$bytes"
  fi
}

IF=$(pick_interface)

if [[ -z "$IF" || ! -r "/sys/class/net/$IF/statistics/rx_bytes" ]]; then
  jq -nc --arg text "󰈂 N/A" --arg tooltip "No active network interface" \
    '{text: $text, tooltip: $tooltip}'
  exit 0
fi

RX1=$(<"/sys/class/net/$IF/statistics/rx_bytes")
TX1=$(<"/sys/class/net/$IF/statistics/tx_bytes")
sleep 1
RX2=$(<"/sys/class/net/$IF/statistics/rx_bytes")
TX2=$(<"/sys/class/net/$IF/statistics/tx_bytes")

DOWN=$((RX2 - RX1))
UP=$((TX2 - TX1))

if ((DOWN > 10485760 || UP > 10485760)); then
  COLOR="#e74c3c"
elif ((DOWN > 5242880 || UP > 5242880)); then
  COLOR="#f1c40f"
else
  COLOR="#a6e3a1"
fi

IP=$(ip -4 addr show "$IF" | awk '/inet / {print $2; exit}' | cut -d/ -f1)
DOWN_HUMAN=$(format_rate "$DOWN")
UP_HUMAN=$(format_rate "$UP")
MODE=$(cat "$MODE_FILE" 2>/dev/null || echo "rate")

if iw dev "$IF" info >/dev/null 2>&1; then
  ICON=""
  SSID=$(iw dev "$IF" link | sed -n 's/^\s*SSID: \(.*\)$/\1/p')
  SIGNAL=$(awk -v ifname="$IF" '$1 ~ ifname ":" { print int($3 * 100 / 70) }' /proc/net/wireless)
  FREQ=$(iw dev "$IF" info | awk '/channel/ {print $2 "MHz"; exit}')
  TOOLTIP="$ICON  IF: $IF SSID: ${SSID:-N/A} 频率: ${FREQ:-N/A} 信号: ${SIGNAL:-N/A}% IP: ${IP:-N/A}"
else
  ICON="󰈀"
  TOOLTIP="$ICON  IF: $IF IP: ${IP:-N/A}"
fi

case "$MODE" in
  ip)
    TEXT="<span color='$COLOR'>$ICON  ${IP:-N/A}</span>"
    ;;
  iface)
    TEXT="<span color='$COLOR'>$ICON  ${IF}</span>"
    ;;
  *)
    TEXT="<span color='$COLOR'>$ICON    ${UP_HUMAN}   ${DOWN_HUMAN}</span>"
    ;;
esac

jq -nc --arg text "$TEXT" --arg tooltip "$TOOLTIP" \
  '{text: $text, tooltip: $tooltip}'
