export ENHANCD_FILTER="fzf --preview 'exa -al --tree --level 1 --group-directories-first --git-ignore --header --git --no-user --no-time --no-filesize --no-permissions {}' --preview-window right,50% --height 35% --reverse --ansi"

export FZF_DEFAULT_OPTS='--height 75% --multi --reverse --margin=0,1 --bind ctrl-f:page-down,ctrl-b:page-up,ctrl-/:toggle-preview --bind pgdn:preview-page-down,pgup:preview-page-up --marker="✚" --pointer="▶" --prompt="❯ " --no-separator --scrollbar="█" --color bg+:#262626,fg+:#dadada,hl:#f09479,hl+:#f09479 --color border:#303030,info:#cfcfb0,header:#80a0ff,spinner:#36c692 --color prompt:#87afff,pointer:#ff5189,marker:#f09479'


[[ -f "$HOME/.secrets.zsh" ]] && source "$HOME/.secrets.zsh"

function setProxy() {
  export http_proxy="http://127.0.0.1:7897"
  export https_proxy=$http_proxy
  export ftp_proxy=$http_proxy
  export all_proxy=$http_proxy
  export rsync_proxy=$http_proxy
  export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"
}

function unsetProxy() {
  unset http_proxy
  unset https_proxy
  unset ftp_proxy
  unset all_proxy
  unset rsync_proxy
  unset no_proxy
}

function proxyStatus() {
  if [[ -n "$http_proxy" || -n "$https_proxy" || -n "$all_proxy" ]]; then
    echo "proxy enabled: ${http_proxy:-$https_proxy}"
  else
    echo "proxy disabled"
  fi
}

alias proxy-on='setProxy'
alias proxy-off='unsetProxy'
alias proxy-status='proxyStatus'

function envStatusSummary() {
  local parts=()

  if [[ -n "$http_proxy" || -n "$https_proxy" || -n "$all_proxy" ]]; then
    parts+=("proxy")
  fi
  if [[ -n "$CANGJIE_SDK_PATH" ]]; then
    parts+=("cj:${CANGJIE_SDK_PATH:t}")
  fi
  if [[ -n "$VIRTUAL_ENV" ]]; then
    parts+=("py:${VIRTUAL_ENV:t}")
  elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    parts+=("conda:${CONDA_DEFAULT_ENV}")
  fi
  if [[ -n "$DIRENV_DIR" ]]; then
    parts+=("direnv")
  fi

  if (( ${#parts[@]} == 0 )); then
    echo "clean"
  else
    echo "${(j: :)parts}"
  fi
}

function updateShellTitle() {
  print -Pn "\e]0;$(envStatusSummary) %~\a"
}

if [[ " ${precmd_functions[*]} " != *" updateShellTitle "* ]]; then
  precmd_functions+=(updateShellTitle)
fi

alias env-status='envStatusSummary'

function swaync-mode() {
  "$HOME/config/swaync/scripts/apply-profile.sh" "$@"
}

[ "$(tty)" = "/dev/tty1" ] && exec bash -lc "$HOME/.local/bin/start-scroll"
[ "$(tty)" = "/dev/tty2" ] && exec bash -lc "$HOME/.local/bin/start-sway"

if is_wsl; then
  source wsl_custom.zsh
fi

function getSdk() {
  TOKEN=$(get_token.py) get_sdk.py $@
}

# Auto-clean on shell exit (default: false); runs in background, non-blocking
# Failures are logged to ~/.zsh_history_cleanup.log
ZSH_CLEAN_HISTORY_AUTO_CLEAN=true

# Similarity threshold 0..1 (default: 0.8)
ZSH_CLEAN_HISTORY_SIMILARITY=0.85

# Max weighted score considered "rare" (default: 3.0).
# Uses time-decay weights: 1.0 for <7d, 0.5 for 8-30d, 0.1 for 31d+.
ZSH_CLEAN_HISTORY_RARE_THRESHOLD=2.0

# Override binary location (default: search PATH, then plugin's target/)
# ZSH_CLEAN_HISTORY_BIN=/path/to/zsh-clean-history
#
export SMART_SUGGESTION_AI_PROVIDER="deepseek"
