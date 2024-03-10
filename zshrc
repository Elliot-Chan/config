# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$HOME/.local/bin/:$HOME/.cargo/bin/:$PATH
export GOPATH=$HOME/.local/go
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

export GOPROXY=https://mirrors.aliyun.com/goproxy/
export HTTP_PROXY="http://192.168.124.2:10809"
# RUSTUP
# export RUSTUP_UPDATE_ROOT="https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup install nightly-YYYY-mm-dd"
# export RUSTUP_DIST_SERVER="https://mirrors.tuna.tsinghua.edu.cn/rustup install nightly-YYYY-mm-dd"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
# ZSH_THEME="powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(git archlinux ag virtualenv command-not-found colorize fasd fzf fd thefuck systemd sudo)

# source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export EDITOR="vim"
function zvm_config() {
  ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
  ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
}

source /usr/share/zsh/share/antigen.zsh
antigen use oh-my-zsh
antigen bundle git
antigen bundle heroku
antigen bundle colorize
antigen bundle fd
antigen bundle fasd
antigen bundle thefuck
antigen bundle command-not-found 
antigen bundle ag
antigen bundle pip
antigen bundle lein
antigen bundle virtualenv
antigen bundle archlinux
antigen bundle command-not-found
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
# antigen bundle zsh-users/zsh-completions
# antigen bundle marlonrichert/zsh-autocomplete
# antigen bundle zsh-users/zsh-history-substring-search
antigen bundle jeffreytse/zsh-vi-mode
antigen bundle desyncr/auto-ls
# Auto updating, both of antigen and the bundles loaded in your config.
antigen bundle unixorn/autoupdate-antigen.zshplugin

# This is a calculator which runs on zsh.
antigen bundle arzzen/calc.plugin.zsh
antigen bundle zdharma/fast-syntax-highlighting
antigen bundle seletskiy/zsh-git-smart-commands
antigen bundle MichaelAquilina/zsh-you-should-use
antigen bundle djui/alias-tips

antigen bundle sudo 

antigen apply

# The plugin will auto execute this zvm_before_init function
function zvm_before_init() {
  zvm_bindkey viins '^[[A' history-beginning-search-backward
  zvm_bindkey viins '^[[B' history-beginning-search-forward
  zvm_bindkey vicmd '^[[A' history-beginning-search-backward
  zvm_bindkey vicmd '^[[B' history-beginning-search-forward
}

source /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste up-line-or-search down-line-or-search expand-or-complete accept-line push-line-or-edit)

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,underline"
# zsh-history-substring-search configuration
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# ZVM_VI_INSERT_ESCAPE_BINDKEY=jk

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
#
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ZSH_COLORIZE_STYLE="colorful"
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
#ZSH_THEME="powerlevel10k/powerlevel10k"

export ZVM_VI_ESCAPE_BINDKEY='jk'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# alias 
alias cat='bat --paging=never'
alias ls='exa'

#eval "$(starship init zsh)"
