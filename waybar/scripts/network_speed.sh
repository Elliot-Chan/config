#!/usr/bin/env bash

IF="wlan0"

RX1=$(cat /sys/class/net/$IF/statistics/rx_bytes)
TX1=$(cat /sys/class/net/$IF/statistics/tx_bytes)
sleep 1
RX2=$(cat /sys/class/net/$IF/statistics/rx_bytes)
TX2=$(cat /sys/class/net/$IF/statistics/tx_bytes)

DOWN=$((RX2 - RX1))
UP=$((TX2 - TX1))

DOWN_KB=$((DOWN / 1024))
UP_KB=$((UP / 1024))

if ((DOWN_KB > 10240 || UP_KB > 10240)); then
  COLOR="#e74c3c"
elif ((DOWN_KB > 5120 || UP_KB > 5120)); then
  COLOR="#f1c40f"
else
  COLOR="#a6e3a1"
fi

IP=$(ip -4 addr show $IF | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
SSID=$(iw dev $IF link | sed -n 's/^\s*SSID: \(.*\)$/\1/p')
SIGNAL=$(grep $IF /proc/net/wireless | awk '{ print int($3 * 100 / 70) }')
FREQ=$(iw dev $IF info | grep channel | awk '{print $2"MHz"}')

TEXT="<span color='$COLOR'>    ${UP_KB}KB/s   ${DOWN_KB}KB/s</span>"
TOOLTIP="  SSID: ${SSID:-N/A} 频率: ${FREQ:-N/A} 信号: ${SIGNAL:-N/A}% IP: ${IP:-N/A}"

jq -nc --arg text "$TEXT" --arg tooltip "$TOOLTIP" \
  '{text: $text, tooltip: $tooltip}'
