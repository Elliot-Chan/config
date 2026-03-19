#!/usr/bin/env bash

set -u

ROOT="/home/elliot/config"
TIMING_MODE=0
ok_count=0
warn_count=0
fail_count=0

if [[ "${1:-}" == "--timing" ]]; then
  TIMING_MODE=1
fi

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

run_check "zsh syntax" zsh -n \
  "$ROOT/zsh/zshrc" \
  "$ROOT/zsh/custom.zsh" \
  "$ROOT/zsh/helper.zsh" \
  "$ROOT/zsh/alias.zsh"

run_check "sheldon config syntax" sh -c 'test -s "$1"' _ "$ROOT/sheldon/plugins.toml"

if rg -q '^ZSH_THEME=""$' "$ROOT/zsh/zshrc"; then
  pass "oh-my-zsh theme disabled"
else
  warn "oh-my-zsh theme enabled"
fi

if ! rg -q '^\[plugins\.git-prompt\]' "$ROOT/sheldon/plugins.toml"; then
  pass "redundant zsh-git-prompt disabled"
else
  warn "redundant zsh-git-prompt enabled"
fi

if rg -q '^DISABLE_UNTRACKED_FILES_DIRTY="true"$' "$ROOT/zsh/zshrc"; then
  pass "omz untracked scan disabled"
else
  warn "omz untracked scan enabled"
fi

if command -v sheldon >/dev/null 2>&1; then
  pass "sheldon installed"
else
  fail "sheldon installed"
fi

if [[ -x /home/elliot/.cache/gitstatus/gitstatusd-linux-x86_64 ]]; then
  pass "gitstatus binary present"
else
  warn "gitstatus binary missing"
fi

hook_output=$(
  zsh -ic 'print -r -- "precmd:${(j: :)precmd_functions}"; print -r -- "chpwd:${(j: :)chpwd_functions}"; print -r -- "preexec:${(j: :)preexec_functions}"' \
    2>/dev/null || true
)

if [[ -n "$hook_output" ]]; then
  pass "interactive hook snapshot"
  printf '%s\n' "$hook_output"
else
  warn "interactive hook snapshot unavailable"
fi

if [[ "$hook_output" == *"precmd_update_git_vars"* || "$hook_output" == *"chpwd_update_git_vars"* ]]; then
  fail "legacy zsh-git-prompt hooks still active"
fi

if [[ "$hook_output" == *"_omz_async_request"* ]]; then
  warn "omz async prompt hook still present"
fi

if (( TIMING_MODE )); then
  measure_ms() {
    local start end
    start=$(date +%s%3N)
    "$@" >/dev/null 2>&1
    end=$(date +%s%3N)
    printf '%s' "$((end - start))"
  }

  startup_ms=$(measure_ms zsh -ic exit)
  printf 'timing:zsh_startup_ms=%s\n' "$startup_ms"

  sample_repo="/home/elliot/Code/working/cangjie_test"
  if [[ -d "$sample_repo/.git" || -f "$sample_repo/.git" ]]; then
    git_status_ms=$(measure_ms git -C "$sample_repo" status --short)
    git_branch_ms=$(measure_ms git -C "$sample_repo" rev-parse --abbrev-ref HEAD)
    printf 'timing:git_status_ms=%s repo=%s\n' "$git_status_ms" "$sample_repo"
    printf 'timing:git_branch_ms=%s repo=%s\n' "$git_branch_ms" "$sample_repo"
  else
    warn "timing repo missing: $sample_repo"
  fi
fi

printf '\nSummary: %d passed, %d warned, %d failed\n' "$ok_count" "$warn_count" "$fail_count"
exit "$fail_count"
