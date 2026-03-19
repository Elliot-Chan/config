#!/usr/bin/env bash

set -euo pipefail

ROOT="$HOME/config/swaync"
PROFILE="${1:-work}"
SRC="$ROOT/profiles/${PROFILE}.json"
DST="$HOME/.config/swaync/config.json"

if [[ ! -f "$SRC" ]]; then
  echo "unknown swaync profile: $PROFILE" >&2
  echo "available: work, focus, silent" >&2
  exit 1
fi

mkdir -p "$(dirname "$DST")"
cp -f "$SRC" "$DST"

if command -v swaync-client >/dev/null 2>&1; then
  swaync-client -rs >/dev/null 2>&1 || true
fi

if command -v notify-send >/dev/null 2>&1; then
  notify-send "swaync" "Applied profile: ${PROFILE}"
fi
