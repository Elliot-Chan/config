#!/usr/bin/zsh
# 等待 HEADLESS-1 出现（最多 ~5 秒，避免竞争）
for _ in $(seq 20); do
  swaymsg -t get_outputs -p | grep -q "name HEADLESS-1" && break
  sleep 0.25
done
pkill -x wayvnc 2>/dev/null || true
# wayvnc -o HEADLESS-1 -r 0.0.0.0 5901
wayvnc -o HDMI-A-2 -r 0.0.0.0 5901
