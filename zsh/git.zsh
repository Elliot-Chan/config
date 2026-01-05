# 推当前分支到远程同名分支
gprb() {
  # 当前分支名
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || {
    echo "⚠ 当前不是本地分支（可能是 detached HEAD）" >&2
    return 1
  }

  # 远端，默认 origin，也可以 gprb upstream
  local remote=${1:-origin}

  echo "👉 git push ${remote} ${branch}"
  git push "${remote}" "${branch}"
}

# 强推当前分支到远程同名分支（force-with-lease）
gprb!() {
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || {
    echo "⚠ 当前不是本地分支（可能是 detached HEAD）" >&2
    return 1
  }

  local remote=${1:-origin}

  echo "🧨 git push --force-with-lease ${remote} ${branch}"
  git push --force-with-lease "${remote}" "${branch}"
}
