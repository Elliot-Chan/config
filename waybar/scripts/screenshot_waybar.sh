#!/usr/bin/env bash

set -u
set -o pipefail

notify() {
  local body="${1:-}"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a waybar -t 1600 "截图" "$body"
  fi
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    notify "缺少命令: $cmd"
    exit 127
  fi
}

source_env_if_present() {
  local env_file="${GCCLIP_ENV_FILE:-"$HOME/.config/gcclip.env"}"
  if [ -f "$env_file" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
  fi
}

resolve_gcclip_bin() {
  local candidate="${GCCLIP_BIN:-"$HOME/.local/bin/gcclip.py"}"
  if [ -x "$candidate" ]; then
    printf '%s' "$candidate"
    return 0
  fi
  if command -v gcclip.py >/dev/null 2>&1; then
    command -v gcclip.py
    return 0
  fi
  notify "找不到 gcclip.py（期望路径：$candidate）"
  exit 127
}

missing_upload_env() {
  local missing=""
  for v in GC_OWNER GC_REPO GC_WRITE_TOKEN; do
    if [ -z "${!v:-}" ]; then
      missing="${missing}${missing:+, }$v"
    fi
  done
  printf '%s' "$missing"
}

capture_area() {
  local log_file="$1"
  require_cmd slurp
  require_cmd grim

  local geometry=""
  if ! geometry="$(slurp 2>>"$log_file")"; then
    notify "已取消"
    exit 0
  fi
  if [ -z "$geometry" ]; then
    notify "已取消"
    exit 0
  fi

  local img=""
  img="$(mktemp --suffix=.png)"
  trap 'rm -f "$img" 2>/dev/null || true' EXIT

  if ! grim -g "$geometry" "$img" 2>>"$log_file"; then
    notify "截图失败（详见 $log_file）"
    exit 1
  fi
  if [ ! -s "$img" ]; then
    notify "截图为空（详见 $log_file）"
    exit 1
  fi
  CAPTURED_IMAGE="$img"
}

log_context() {
  local log_file="$1"
  local action="$2"
  {
    echo "[$(date -Is)] $action"
    echo "PATH=$PATH"
    echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
    echo "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-}"
  } >>"$log_file" 2>&1 || true
}

action_area_copy() {
  local log_file="$1"
  local img="$2"

  if command -v copyq >/dev/null 2>&1; then
    local copyq_tab="${COPYQ_TAB:-&clipboard}"
    local label="screenshot $(date -Is)"
    if timeout 3s copyq -s '' tab "$copyq_tab" insert 0 "$label" >>"$log_file" 2>&1 &&
      timeout 3s copyq -s '' tab "$copyq_tab" write 0 image/png - <"$img" >>"$log_file" 2>&1 &&
      timeout 3s copyq -s '' tab "$copyq_tab" select 0 >>"$log_file" 2>&1; then
      require_cmd wl-copy
      if ! wl-copy --type image/png <"$img" 2>>"$log_file"; then
        notify "已写入 CopyQ，但写入剪贴板失败（详见 $log_file）"
        exit 1
      fi
      {
        echo "copied=$img"
        echo "copyq_tab=$copyq_tab"
        echo "copyq item types after copy:"
        copyq -s '' tab "$copyq_tab" read '?' 0 2>&1 || true
        echo "clipboard types after wl-copy:"
        wl-paste --list-types 2>&1 || true
      } >>"$log_file" 2>&1 || true
      notify "已复制截图到 CopyQ 和剪贴板"
      return
    fi
    echo "copyq copy failed; falling back to wl-copy" >>"$log_file" 2>&1 || true
  fi

  require_cmd wl-copy
  if ! wl-copy --type image/png <"$img" 2>>"$log_file"; then
    notify "写入剪贴板失败（详见 $log_file）"
    exit 1
  fi
  {
    echo "copied=$img"
    echo "clipboard types after copy:"
    wl-paste --list-types 2>&1 || true
  } >>"$log_file" 2>&1 || true

  notify "已复制截图到剪贴板"
}

action_area_upload() {
  local log_file="$1"
  local img="$2"

  source_env_if_present
  local missing=""
  missing="$(missing_upload_env)"
  if [ -n "$missing" ]; then
    notify "缺少环境变量: $missing (可写入 ~/.config/gcclip.env)"
    echo "missing env: $missing" >>"$log_file" 2>&1 || true
    exit 1
  fi

  local gcclip_bin=""
  gcclip_bin="$(resolve_gcclip_bin)"
  echo "gcclip_bin=$gcclip_bin" >>"$log_file" 2>&1 || true
  if ! "$gcclip_bin" copy-image --file "$img" >>"$log_file" 2>&1; then
    notify "上传失败：gcclip 写入失败（详见 $log_file）"
    exit 1
  fi
  notify "已上传截图"
}

main() {
  local action="${1:-}"
  case "$action" in
  area-copy | area-upload) ;;
  *)
    echo "usage: $0 {area-copy|area-upload}" >&2
    exit 2
    ;;
  esac

  local log_file="${SCREENSHOT_WAYBAR_LOG:-"$HOME/.cache/waybar-screenshot.log"}"
  mkdir -p "$(dirname "$log_file")" >/dev/null 2>&1 || true
  log_context "$log_file" "$action"

  CAPTURED_IMAGE=""
  capture_area "$log_file"

  case "$action" in
  area-copy)
    action_area_copy "$log_file" "$CAPTURED_IMAGE"
    ;;
  area-upload)
    action_area_upload "$log_file" "$CAPTURED_IMAGE"
    ;;
  esac
}

main "$@"
