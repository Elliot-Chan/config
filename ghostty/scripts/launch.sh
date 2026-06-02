#!/usr/bin/env bash
set -euo pipefail

config_file="${GHOSTTY_CONFIG_FILE:-$HOME/config/ghostty/config.ghostty}"

class=""
cwd=""
title=""
command_args=()

map_class() {
  case "$1" in
  dropdown-terminal) printf '%s\n' 'com.elliot.ghostty.dropdown' ;;
  bottom-terminal) printf '%s\n' 'com.elliot.ghostty.bottom' ;;
  *) printf '%s\n' "$1" ;;
  esac
}

while (($#)); do
  case "$1" in
  --class)
    class="$(map_class "${2:?missing value for --class}")"
    shift 2
    ;;
  --class=*)
    class="$(map_class "${1#--class=}")"
    shift
    ;;
  --directory | --working-directory | --cwd)
    cwd="${2:?missing value for $1}"
    shift 2
    ;;
  --directory=* | --working-directory=* | --cwd=*)
    cwd="${1#*=}"
    shift
    ;;
  --title)
    title="${2:?missing value for --title}"
    shift 2
    ;;
  --title=*)
    title="${1#--title=}"
    shift
    ;;
  --detach)
    shift
    ;;
  --)
    shift
    command_args=("$@")
    break
    ;;
  -e)
    shift
    command_args=("$@")
    break
    ;;
  *)
    command_args=("$@")
    break
    ;;
  esac
done

args=("--config-file=$config_file")

if [[ -n "$class" ]]; then
  args+=("--class=$class")
fi

if [[ -n "$cwd" ]]; then
  args+=("--working-directory=$cwd")
fi

if [[ -n "$title" ]]; then
  args+=("--title=$title")
fi

if [[ "${#command_args[@]}" -gt 0 ]]; then
  args+=("-e" "${command_args[@]}")
fi

exec ghostty "${args[@]}"
