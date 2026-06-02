#!/usr/bin/env bash
set -euo pipefail

if [[ "${KITTY_FORCE_SOFTWARE_GL:-1}" != "0" ]]; then
  export LIBGL_ALWAYS_SOFTWARE=1
fi

exec kitty "$@"
