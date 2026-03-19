#!/usr/bin/env bash

set -u

ROOT="/home/elliot/config"
WAYBAR_ROOT="$ROOT/waybar"
ok_count=0
warn_count=0
fail_count=0

pass() {
  printf '[PASS] %s\n' "$1"
  ok_count=$((ok_count + 1))
}

warn() {
  printf '[WARN] %s\n' "$1"
  warn_count=$((warn_count + 1))
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

run_check "waybar generator" python3 "$WAYBAR_ROOT/generate_config.py"
run_check "weather python syntax" python3 -m py_compile "$WAYBAR_ROOT/scripts/weather.py"
run_check "waybar shell scripts" bash -n \
  "$WAYBAR_ROOT/scripts/module_action.sh" \
  "$WAYBAR_ROOT/scripts/network_speed.sh" \
  "$WAYBAR_ROOT/scripts/open_terminal_tool.sh"
run_check "generated waybar json" python3 -c 'import json, pathlib; text=pathlib.Path("/home/elliot/config/waybar/config.jsonc").read_text(encoding="utf-8"); json.loads(text.split("\n", 1)[1])'
run_check "weather command json" zsh -lc '[[ -f ~/.custom.zsh ]] && source ~/.custom.zsh; python3 ~/.config/waybar/scripts/weather.py | python3 -c "import json,sys; data=json.load(sys.stdin); assert isinstance(data.get(\"text\"), str)"'
run_check "network command json" bash -lc '~/.config/waybar/scripts/network_speed.sh | python3 -c "import json,sys; data=json.load(sys.stdin); assert isinstance(data.get(\"text\"), str)"'

if [[ "$WAYBAR_ROOT/generate_config.py" -nt "$WAYBAR_ROOT/config.jsonc" ]]; then
  warn "config.jsonc older than generate_config.py"
else
  pass "config.jsonc up to date"
fi

for cmd in python3 wl-copy; do
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "dependency: $cmd"
  else
    fail "dependency: $cmd"
  fi
done

if command -v swaync-client >/dev/null 2>&1; then
  pass "dependency: swaync-client"
else
  warn "dependency: swaync-client"
fi

if pgrep -x waybar >/dev/null 2>&1; then
  pass "waybar process running"
else
  warn "waybar process running"
fi

if pgrep -x swaync >/dev/null 2>&1; then
  pass "swaync process running"
else
  warn "swaync process running"
fi

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

if [[ -n "${QWEATHER_KID:-}" || -n "${QWEATHER_SUB:-}" ]]; then
  pass "qweather env loaded in current shell"
else
  warn "qweather env not loaded in current shell"
fi

for mode_file in /home/elliot/.cache/waybar/weather.mode /home/elliot/.cache/waybar/network.mode; do
  if [[ -f "$mode_file" ]]; then
    pass "mode cache present: ${mode_file##*/}"
  else
    warn "mode cache missing: ${mode_file##*/}"
  fi
done

iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
if [[ -n "$iface" ]]; then
  pass "default route interface: $iface"
else
  warn "default route interface missing"
fi

printf '\nSummary: %d passed, %d warned, %d failed\n' "$ok_count" "$warn_count" "$fail_count"
exit "$fail_count"
