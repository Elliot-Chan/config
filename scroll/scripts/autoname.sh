#!/usr/bin/env bash
set -euo pipefail

need_cmd() { command -v "$1" >/dev/null 2>&1 || {
  echo "missing $1" >&2
  exit 1
}; }
need_cmd jq

pick_ipc() {
  if command -v scrollmsg >/dev/null 2>&1 && scrollmsg -t get_tree >/dev/null 2>&1; then
    echo scrollmsg
    return 0
  fi

  if command -v swaymsg >/dev/null 2>&1 && swaymsg -t get_tree >/dev/null 2>&1; then
    echo swaymsg
    return 0
  fi

  echo "missing working scrollmsg/swaymsg IPC command" >&2
  return 1
}

IPC_CMD="$(pick_ipc)"

# 命中第一个规则就作为 workspace 名称（优先级从上到下）
# 规则格式：
#   app:<regex>  => <label>
#   title:<regex> => <label>
#
# regex 是 jq 的正则；忽略大小写用 (?i) 前缀（和你 toml 一致）
RULES=(
  # 你 toml 里的 VSCode 场景（title 规则）
  'title:(?i)working/cangjie_stdx.* visual studio code =>   stdx(W)'
  'title:(?i)cangjie_stdx.* visual studio code =>   stdx'
  'title:(?i)working/cangjie_runtime/stdlib.* - visual studio code =>   stdlib(W)'
  'title:(?i)working/cangjie_runtime/std - visual studio code =>   stdlib(W)'
  'title:(?i)std.* visual studio code =>   stdlib'
  'title:(?i)working/cangjie_runtime.* - visual studio code =>   runtime(W)'
  'title:(?i)cangjie_runtime.* - visual studio code =>   runtime'
  'title:(?i)working/cangjie_test.* visual studio code =>   tests(W)'
  'title:(?i)working/cangjie_compiler.* - visual studio code =>   compiler(W)'
  'title:(?i)cangjie_compiler.* - visual studio code =>   compiler'

  # 你 toml 里的浏览器/工具（app_id 规则）
  'app:google-chrome|Google-chrome|Chromium => '
  'app:firefox|Nightly|firefoxdeveloperedition => '
  'app:kitty|org.wezfurlong.wezterm|foot|Alacritty => '
  'app:code|Code|code-oss => '
  'app:bottom-terminal => '
  'app:org.gnome.Nautilus|eog => '
)

# 没命中时不改名（也可以改成一个默认，如 ""）
FALLBACK=""

# 保留数字前缀： "3" or "3:any" -> "3: <label>"
KEEP_NUM_PREFIX=1

# 不处理这些 workspace（按需加）
SKIP_WS_RE='^(__i3_scratch|scratch|special:)$'

list_workspaces() {
  local tree_json="$1"
  jq -r '
    .. | objects
    | select(.type?=="workspace")
    | .name
  ' <<<"$tree_json"
}

num_prefix_of() {
  local name="$1"
  if [[ "$name" =~ ^([0-9]+)(:.*)?$ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

pick_label_for_ws() {
  local wsname="$1"
  local tree_json="$2"

  # 取出该 workspace 内所有窗口（平铺）
  # 每个元素：{"app_id":"...","title":"..."}
  mapfile -t wins < <(
    jq -c --arg ws "$wsname" '
      .. | objects
      | select(.type?=="workspace" and .name==$ws)
      | .. | objects
      | select(.type?=="con" or .type?=="floating_con")
      | select((.app_id? // "") != "" or (.name? // "") != "")
      | {app_id:(.app_id // ""), title:(.name // "")}
    ' <<<"$tree_json"
  )

  local -a labels=()

  # 对每个窗口：按 RULES 顺序找第一条命中
  local w app title line lhs rhs kind re matched
  for w in "${wins[@]}"; do
    app="$(jq -r '.app_id' <<<"$w")"
    title="$(jq -r '.title' <<<"$w")"

    matched=""
    for line in "${RULES[@]}"; do
      lhs="${line%%=>*}"
      rhs="${line#*=> }"
      lhs="$(echo "$lhs" | sed 's/[[:space:]]*$//')"
      kind="${lhs%%:*}"
      re="${lhs#*:}"

      case "$kind" in
      app)
        # app_id 用 regex 匹配（你原来就是这么写的）
        if jq -e --arg s "$app" --arg re "$re" '($s|test($re))' >/dev/null <<<"null"; then
          matched="$rhs"
        fi
        ;;
      title)
        if jq -e --arg s "$title" --arg re "$re" '($s|test($re))' >/dev/null <<<"null"; then
          matched="$rhs"
        fi
        ;;
      esac

      [[ -n "$matched" ]] && break
    done

    [[ -n "$matched" ]] && labels+=("$matched")
  done

  # 去重（按整串去重，保持顺序）
  local -a uniq=()
  local item seen u
  for item in "${labels[@]}"; do
    seen=0
    for u in "${uniq[@]}"; do
      [[ "$u" == "$item" ]] && {
        seen=1
        break
      }
    done
    [[ "$seen" -eq 0 ]] && uniq+=("$item")
  done

  if [[ "${#uniq[@]}" -eq 0 ]]; then
    echo "$FALLBACK"
    return 0
  fi

  # 拼接
  local sep="${SEPARATOR:- }"
  local out=""
  for item in "${uniq[@]}"; do
    if [[ -z "$out" ]]; then
      out="$item"
    else
      out="${out}${sep}${item}"
    fi
  done

  echo "$out"
}

main() {
  local tree ws label prefix target
  tree="$("$IPC_CMD" -t get_tree)"

  while IFS= read -r ws; do
    [[ -z "$ws" ]] && continue
    [[ "$ws" =~ $SKIP_WS_RE ]] && continue

    label="$(pick_label_for_ws "$ws" "$tree")"
    [[ -z "$label" ]] && continue

    prefix=""
    if [[ "$KEEP_NUM_PREFIX" -eq 1 ]]; then
      prefix="$(num_prefix_of "$ws")"
    fi

    if [[ -n "$prefix" ]]; then
      target="${prefix}: ${label}"
    else
      target="${label}"
    fi

    [[ "$ws" == "$target" ]] && continue
    "$IPC_CMD" "rename workspace \"${ws}\" to \"${target}\"" >/dev/null
  done < <(list_workspaces "$tree")
}

main
