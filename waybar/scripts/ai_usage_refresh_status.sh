#!/usr/bin/env bash

set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
STATE_FILE="${AI_USAGE_STATE_FILE:-$CACHE_DIR/ai_usage_refresh.json}"
MAX_AGE_SECONDS="${AI_USAGE_MAX_AGE_SECONDS:-690}"

[[ -f "$STATE_FILE" ]] || exit 1

updated_at="$(
  python3 -c 'import json,sys; print(int(json.load(open(sys.argv[1])).get("updated_at", 0)))' "$STATE_FILE" 2>/dev/null
)"

[[ "$updated_at" =~ ^[0-9]+$ ]] || exit 1

now="$(date +%s)"
age=$((now - updated_at))

(( age >= 0 && age <= MAX_AGE_SECONDS ))
