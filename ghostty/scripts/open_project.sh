#!/usr/bin/env bash
set -euo pipefail

projects_file="${GHOSTTY_PROJECTS_FILE:-$HOME/config/ghostty/projects.tsv}"
launcher="${GHOSTTY_LAUNCHER:-$HOME/config/ghostty/scripts/launch.sh}"

choice="$(
  awk -F '\t' '{ print $1 "\t" $2 "\t" $3 }' "$projects_file" |
    fzf --with-nth=2,3 --delimiter='\t' --prompt='project> '
)"

[[ -n "$choice" ]] || exit 0

id="${choice%%$'\t'*}"
rest="${choice#*$'\t'}"
label="${rest%%$'\t'*}"
cwd="${rest#*$'\t'}"

exec "$launcher" --title "$label" --directory "$cwd"
