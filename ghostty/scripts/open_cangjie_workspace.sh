#!/usr/bin/env bash
set -euo pipefail

launcher="${GHOSTTY_LAUNCHER:-$HOME/config/ghostty/scripts/launch.sh}"

"$launcher" --title runtime --directory /home/elliot/Code/working/cangjie_runtime/stdlib &
"$launcher" --title stdx --directory /home/elliot/Code/working/cangjie_stdx &
disown
