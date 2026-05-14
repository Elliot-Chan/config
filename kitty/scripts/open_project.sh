#!/usr/bin/env bash
set -euo pipefail

projects_file="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/projects.tsv"

if [[ ! -f "$projects_file" ]]; then
  projects_file="$HOME/config/kitty/projects.tsv"
fi

choice="$(
  awk -F '\t' '{ print $1 "\t" $2 "\t" $3 }' "$projects_file" |
    fzf --with-nth=2,3 --delimiter='\t' --prompt='project> '
)"

[[ -n "$choice" ]] || exit 0

id="${choice%%$'\t'*}"
rest="${choice#*$'\t'}"
label="${rest%%$'\t'*}"
cwd="${rest#*$'\t'}"

exec kitty @ --to unix:/tmp/kitty-elliot launch \
  --type=tab \
  --cwd="$cwd" \
  --tab-title="$label" \
  zsh -l
