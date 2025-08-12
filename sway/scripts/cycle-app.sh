#!/bin/bash
# 循环切换某个 app 的窗口所在 workspace
# 用法: cycle-app.sh <app_id/class>

APP="$1"
STATE_FILE="/tmp/sway-cycle-$APP"

# 获取所有该应用的窗口 ID 列表
WINS=($(swaymsg -t get_tree | jq -r "
  recurse(.nodes[]?, .floating_nodes[]?)
  | select(.app_id == \"$APP\" or .window_properties.class == \"$APP\")
  | .id"))

# 如果没有匹配窗口就退出
[ ${#WINS[@]} -eq 0 ] && exit 1

# 读取上次的索引
if [ -f "$STATE_FILE" ]; then
  LAST=$(cat "$STATE_FILE")
else
  LAST=-1
fi

# 计算下一个索引
NEXT=$(((LAST + 1) % ${#WINS[@]}))

# 保存当前索引
echo "$NEXT" >"$STATE_FILE"

# 切换焦点（会自动跳到那个窗口所在的 workspace）
swaymsg "[con_id=${WINS[$NEXT]}] focus"
