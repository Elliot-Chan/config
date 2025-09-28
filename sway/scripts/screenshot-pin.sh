#!/bin/bash

TMPDIR="${XDG_CACHE_HOME:-$HOME/.cache}/sway-screenshots"
mkdir -p "$TMPDIR"
FILE="$TMPDIR/shot_$(date +%s).png"

grim -g "$(slurp)" "$FILE"

read WIDTH HEIGHT < <(identify -format "%w %h" "$FILE")
swayimg "$FILE" &
sleep 0.2
swaymsg "[app_id=\"swayimg\"] floating enable"
swaymsg "[app_id=\"swayimg\"] resize set $WIDTH $HEIGHT"

SCREEN_W=$(swaymsg -t get_outputs | jq -r '.[0].current_mode.width')
SCREEN_H=$(swaymsg -t get_outputs | jq -r '.[0].current_mode.height')
X_POS=$((SCREEN_W - WIDTH - 20)) # 20px margin
Y_POS=$((SCREEN_H - HEIGHT - 20))

# swaymsg "[app_id=\"swayimg\"] move position $X_POS $Y_POS"
swaymsg "[app_id=\"swayimg\"] sticky enable"
