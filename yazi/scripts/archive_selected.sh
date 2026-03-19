#!/usr/bin/env bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
  exit 1
fi

dest_dir="$HOME/down"
mkdir -p "$dest_dir"

timestamp=$(date +%Y%m%d-%H%M%S)
if [[ $# -eq 1 ]]; then
  base_name=$(basename "$1")
  archive_name="${base_name}.tar.gz"
else
  archive_name="selection-${timestamp}.tar.gz"
fi

archive_path="${dest_dir}/${archive_name}"

compressor=(gzip)
if command -v pigz >/dev/null 2>&1; then
  compressor=(pigz)
fi

tar --use-compress-program="${compressor[0]}" -cf "$archive_path" "$@"

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Yazi" "Archive created: ${archive_path}"
fi
