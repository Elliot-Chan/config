#!/usr/bin/env bash
set -euo pipefail

role="${1:-}"
if [[ -z "$role" ]]; then
  echo "usage: ${0##*/} <bottom-terminal|dropdown-terminal>" >&2
  exit 2
fi

case "$role" in
bottom-terminal | dropdown-terminal) ;;
*)
  echo "unsupported scratch terminal role: $role" >&2
  exit 2
  ;;
esac

term="${TERMINAL_LAUNCHER:-$HOME/config/ghostty/scripts/launch.sh}"

mapped_role() {
  case "$1" in
  dropdown-terminal) printf '%s\n' 'com.elliot.ghostty.dropdown' ;;
  bottom-terminal) printf '%s\n' 'com.elliot.ghostty.bottom' ;;
  *) printf '%s\n' "$1" ;;
  esac
}

match_role="$(mapped_role "$role")"

tree="$(scrollmsg -t get_tree)"
target_ws="$(
  scrollmsg -t get_workspaces | jq -r '
    [ .[] | select(.focused? == true) | .name ][0] // empty
  '
)"

mapfile -t visible_ids < <(
  jq -r --arg role "$role" --arg match_role "$match_role" '
    .. | objects
    | select(.type? == "con" or .type? == "floating_con")
    | select(
        (.app_id? // "") == $role
        or (.window_properties.class? // "") == $role
        or (.app_id? // "") == $match_role
        or (.window_properties.class? // "") == $match_role
      )
    | select(.visible? == true)
    | .id
  ' <<<"$tree"
)

if [[ "${#visible_ids[@]}" -gt 0 ]]; then
  for con_id in "${visible_ids[@]}"; do
    scrollmsg "[con_id=${con_id}] move to scratchpad" >/dev/null
  done
  exit 0
fi

con_id="$(
  jq -r --arg role "$role" --arg match_role "$match_role" '
    [
      .. | objects
      | select(.type? == "con" or .type? == "floating_con")
      | select(
          (.app_id? // "") == $role
          or (.window_properties.class? // "") == $role
          or (.app_id? // "") == $match_role
          or (.window_properties.class? // "") == $match_role
        )
      | select(.visible? != true)
      | .id
    ][0] // empty
  ' <<<"$tree"
)"

show_existing() {
  local con_id="$1"
  local move_target="workspace current"

  if [[ -n "$target_ws" ]]; then
    target_ws="${target_ws//\\/\\\\}"
    target_ws="${target_ws//\"/\\\"}"
    move_target="workspace \"${target_ws}\""
  fi

  case "$role" in
  dropdown-terminal)
    scrollmsg "[con_id=${con_id}] move to ${move_target}; [con_id=${con_id}] floating enable; [con_id=${con_id}] resize set 100ppt 40ppt; [con_id=${con_id}] move position 0 0; [con_id=${con_id}] border pixel 1; [con_id=${con_id}] focus" >/dev/null
    ;;
  bottom-terminal)
    scrollmsg "[con_id=${con_id}] move to ${move_target}; [con_id=${con_id}] floating enable; [con_id=${con_id}] resize set 100ppt 40ppt; [con_id=${con_id}] move position 0ppt 60ppt; [con_id=${con_id}] opacity 0.95; [con_id=${con_id}] focus" >/dev/null
    ;;
  esac
}

if [[ -z "$con_id" ]]; then
  exec "$term" --class "$role"
fi

show_existing "$con_id"
