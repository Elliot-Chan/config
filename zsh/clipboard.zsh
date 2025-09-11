#!/usr/bin/env bash
# 用 GitHub 仓库做中转的云剪贴板
# 支持文本和图片
# 用法：
#   clip-sync.sh send [text|image]
#   clip-sync.sh recv

set -euo pipefail

REPO_DIR="$HOME/.cloud-clipboard"   # 你的 repo clone 路径
FILE_TEXT="$REPO_DIR/clip.txt"
FILE_IMAGE="$REPO_DIR/clip.png"

if [[ ! -d "$REPO_DIR/.git" ]]; then
    echo "❌ 仓库目录不存在: $REPO_DIR"
    exit 1
fi

send_text() {
    wl-paste > "$FILE_TEXT"
    rm -f "$FILE_IMAGE"
    cd "$REPO_DIR"
    git add "$FILE_TEXT" && git commit -m "update text" || true
    git push
    echo "✅ 文本已上传"
}

send_image() {
    wl-paste --type image/png > "$FILE_IMAGE"
    rm -f "$FILE_TEXT"
    cd "$REPO_DIR"
    git add "$FILE_IMAGE" && git commit -m "update image" || true
    git push
    echo "✅ 图片已上传"
}

recv() {
    cd "$REPO_DIR"
    git pull --rebase --autostash

    if [[ -f "$FILE_TEXT" ]]; then
        cat "$FILE_TEXT" | wl-copy
        echo "📋 已复制文本到剪贴板"
    elif [[ -f "$FILE_IMAGE" ]]; then
        wl-copy < "$FILE_IMAGE"
        echo "🖼 已复制图片到剪贴板"
    else
        echo "⚠️ 没有找到剪贴板内容"
    fi
}

case "${1:-}" in
    send)
        if [[ "${2:-}" == "text" ]]; then
            send_text
        elif [[ "${2:-}" == "image" ]]; then
            send_image
        else
            echo "用法: $0 send [text|image]"
            exit 1
        fi
        ;;
    recv)
        recv
        ;;
    *)
        echo "用法:"
        echo "  $0 send text    # 发送文本"
        echo "  $0 send image   # 发送图片"
        echo "  $0 recv         # 接收"
        ;;
esac

