#!/usr/bin/env bash

set -u

ROOT="/home/elliot/config"
ok_count=0
fail_count=0

pass() {
  printf '[PASS] %s\n' "$1"
  ok_count=$((ok_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

run_check() {
  local label=$1
  shift
  if "$@" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label"
  fi
}

run_check "zsh syntax" zsh -n "$ROOT/zsh/zshrc" "$ROOT/zsh/custom.zsh" "$ROOT/zsh/helper.zsh"
run_check "waybar shell scripts" bash -n \
  "$ROOT/waybar/scripts/module_action.sh" \
  "$ROOT/waybar/scripts/network_speed.sh" \
  "$ROOT/waybar/scripts/open_terminal_tool.sh"
run_check "yazi helper scripts" bash -n \
  "$ROOT/yazi/scripts/archive_selected.sh" \
  "$ROOT/yazi/scripts/video_to_gif.sh" \
  "$ROOT/yazi/scripts/yazi-copy-path.sh" \
  "$ROOT/yazi/scripts/yazi-open-here.sh"
run_check "waybar generator" python3 "$ROOT/waybar/generate_config.py"
run_check "swaync json" python3 -c 'import json; json.load(open("/home/elliot/.config/swaync/config.json"))'
run_check "waybar config json" python3 -c 'import json, pathlib; text=pathlib.Path("/home/elliot/config/waybar/config.jsonc").read_text(encoding="utf-8"); json.loads(text.split("\n", 1)[1])'
run_check "wezterm lua" lua -e 'assert(loadfile("/home/elliot/config/wezterm/config/bindings.lua")); assert(loadfile("/home/elliot/config/wezterm/config/projects.lua"))'
run_check "wezterm project json" python3 -c 'import json; json.load(open("/home/elliot/config/wezterm/config/projects.json"))'
run_check "nvim lua" lua -e 'assert(loadfile("/home/elliot/config/nvim/init.lua")); assert(loadfile("/home/elliot/config/nvim/lua/config/commands.lua")); assert(loadfile("/home/elliot/config/nvim/lua/plugins/lualine.lua"))'
run_check "swaync profile json" python3 -c 'import json; json.load(open("/home/elliot/config/swaync/profiles/work.json")); json.load(open("/home/elliot/config/swaync/profiles/focus.json")); json.load(open("/home/elliot/config/swaync/profiles/silent.json"))'

if [[ -f /home/elliot/.config/waybar/.qweather_private_key ]]; then
  perms=$(stat -c '%a' /home/elliot/.config/waybar/.qweather_private_key 2>/dev/null || true)
  if [[ "$perms" == "600" ]]; then
    pass "qweather key perms"
  else
    fail "qweather key perms (expected 600, got ${perms:-unknown})"
  fi
else
  fail "qweather key present"
fi

printf '\nSummary: %d passed, %d failed\n' "$ok_count" "$fail_count"
exit "$fail_count"
