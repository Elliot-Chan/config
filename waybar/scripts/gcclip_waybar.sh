#!/usr/bin/env bash

set -u
set -o pipefail

notify() {
  local title="GCClip"
  local body="${1:-}"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a waybar -t 1600 "$title" "$body"
  fi
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    notify "缺少命令: $cmd"
    exit 127
  fi
}

detect_image_mime() {
  local file="$1"
  local hex=""
  hex="$(head -c 12 "$file" 2>/dev/null | od -An -t x1 2>/dev/null | tr -d ' \n')"
  case "$hex" in
  89504e470d0a1a0a*) echo "image/png" ;;
  ffd8ff*) echo "image/jpeg" ;;
  474946383761* | 474946383961*) echo "image/gif" ;;
  52494646????????57454250*) echo "image/webp" ;;
  *) echo "" ;;
  esac
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

source_env_if_present() {
  local env_file="${GCCLIP_ENV_FILE:-"$HOME/.config/gcclip.env"}"
  if [ -f "$env_file" ]; then
    # Ensure variables from env file are exported to child processes.
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
  fi
}

missing_required_env() {
  local action="${1:-}"
  local missing=""
  for v in GC_OWNER GC_REPO; do
    if [ -z "${!v:-}" ]; then
      missing="${missing}${missing:+, }$v"
    fi
  done
  case "$action" in
  copy | copy-image)
    if [ -z "${GC_WRITE_TOKEN:-}" ]; then
      missing="${missing}${missing:+, }GC_WRITE_TOKEN"
    fi
    ;;
  paste | paste-image)
    if [ -z "${GC_READ_TOKEN:-${GC_WRITE_TOKEN:-}}" ]; then
      missing="${missing}${missing:+, }GC_READ_TOKEN/GC_WRITE_TOKEN"
    fi
    ;;
  *)
    if [ -z "${GC_READ_TOKEN:-${GC_WRITE_TOKEN:-}}" ]; then
      missing="${missing}${missing:+, }GC_READ_TOKEN/GC_WRITE_TOKEN"
    fi
    ;;
  esac
  printf '%s' "$missing"
}

main() {
  local action="${1:-}"
  if [ -z "$action" ]; then
    echo "usage: $0 {copy|paste|copy-image|paste-image}" >&2
    exit 2
  fi

  local log_file="${GCCLIP_WAYBAR_LOG:-"$HOME/.cache/waybar-gcclip.log"}"
  mkdir -p "$(dirname "$log_file")" >/dev/null 2>&1 || true

  source_env_if_present
  local gcclip_bin
  gcclip_bin="$(resolve_gcclip_bin)"

  local local_missing
  local_missing="$(missing_required_env "$action")"
  if [ -n "$local_missing" ]; then
    notify "缺少环境变量: $local_missing (可写入 ~/.config/gcclip.env)"
    {
      echo "[$(date -Is)] missing env: $local_missing"
      echo "PATH=$PATH"
      echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
      echo "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-}"
    } >>"$log_file" 2>&1 || true
    exit 1
  fi

  case "$action" in
  copy)
    require_cmd wl-paste
    notify "开始复制"
    {
      echo "[$(date -Is)] copy"
      echo "gcclip_bin=$gcclip_bin"
      echo "PATH=$PATH"
      echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
      echo "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-}"
    } >>"$log_file" 2>&1 || true
    tmp="$(mktemp)"
    trap 'rm -f "$tmp" 2>/dev/null || true' RETURN
    if ! wl-paste -n >"$tmp" 2>>"$log_file"; then
      notify "复制失败：wl-paste 读取剪贴板失败（详见 $log_file）"
      exit 1
    fi
    if [ ! -s "$tmp" ]; then
      echo "[$(date -Is)] clipboard empty; trying primary selection" >>"$log_file" 2>&1 || true
      if ! wl-paste -n -p >"$tmp" 2>>"$log_file"; then
        notify "复制失败：wl-paste 读取主选区失败（详见 $log_file）"
        exit 1
      fi
    fi
    if [ ! -s "$tmp" ]; then
      echo "[$(date -Is)] clipboard+primary empty; available types:" >>"$log_file" 2>&1 || true
      wl-paste -l >>"$log_file" 2>&1 || true
      notify "剪贴板为空（先复制文本再点；详见 $log_file）"
      exit 1
    fi
    if ! "$gcclip_bin" copy-text <"$tmp" >>"$log_file" 2>&1; then
      notify "复制失败：gcclip 写入失败（终端可跑：wl-paste -n | $gcclip_bin copy-text；详见 $log_file）"
      exit 1
    fi
    notify "复制成功"
    ;;
  copy-image)
    notify "开始上传剪贴板图片"
    {
      echo "[$(date -Is)] copy-image"
      echo "gcclip_bin=$gcclip_bin"
      echo "PATH=$PATH"
      echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
      echo "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-}"
    } >>"$log_file" 2>&1 || true

    if ! "$gcclip_bin" copy-image --from-clipboard >>"$log_file" 2>&1; then
      notify "上传失败：读取剪贴板图片或 gcclip 上传失败（详见 $log_file）"
      exit 1
    fi
    notify "已上传图片"
    ;;
  paste)
    require_cmd wl-copy
    notify "开始粘贴"
    {
      echo "[$(date -Is)] paste"
      echo "gcclip_bin=$gcclip_bin"
      echo "PATH=$PATH"
      echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
      echo "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-}"
    } >>"$log_file" 2>&1 || true
    if ! "$gcclip_bin" paste-text 2>>"$log_file" | wl-copy 2>>"$log_file"; then
      notify "粘贴失败（终端排查：$gcclip_bin paste-text；详见 $log_file）"
      exit 1
    fi
    notify "粘贴成功"
    ;;
  paste-image)
    require_cmd wl-copy
    notify "开始粘贴图片"
    {
      echo "[$(date -Is)] paste-image"
      echo "gcclip_bin=$gcclip_bin"
      echo "PATH=$PATH"
      echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
      echo "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-}"
    } >>"$log_file" 2>&1 || true

    local out=""
    out="$(mktemp --suffix=.img)"
    trap 'rm -f "$out" 2>/dev/null || true' RETURN
    if ! "$gcclip_bin" paste-image --out "$out" >>"$log_file" 2>&1; then
      notify "粘贴失败：gcclip paste-image 失败（详见 $log_file）"
      exit 1
    fi
    if [ ! -s "$out" ]; then
      notify "粘贴失败：图片为空（详见 $log_file）"
      exit 1
    fi
    local mime=""
    mime="$(detect_image_mime "$out")"
    if [ -z "$mime" ]; then
      notify "粘贴失败：无法识别图片格式（详见 $log_file）"
      exit 1
    fi
    if ! wl-copy --type "$mime" <"$out" 2>>"$log_file"; then
      notify "写入剪贴板失败（详见 $log_file）"
      exit 1
    fi
    notify "已复制图片到剪贴板"
    ;;
  *)
    echo "unknown action: $action" >&2
    exit 2
    ;;
  esac
}

main "$@"
