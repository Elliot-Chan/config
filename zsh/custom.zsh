export ENHANCD_FILTER="fzf --preview 'exa -al --tree --level 1 --group-directories-first --git-ignore --header --git --no-user --no-time --no-filesize --no-permissions {}' --preview-window right,50% --height 35% --reverse --ansi"

export FZF_DEFAULT_OPTS='--height 75% --multi --reverse --margin=0,1 --bind ctrl-f:page-down,ctrl-b:page-up,ctrl-/:toggle-preview --bind pgdn:preview-page-down,pgup:preview-page-up --marker="✚" --pointer="▶" --prompt="❯ " --no-separator --scrollbar="█" --color bg+:#262626,fg+:#dadada,hl:#f09479,hl+:#f09479 --color border:#303030,info:#cfcfb0,header:#80a0ff,spinner:#36c692 --color prompt:#87afff,pointer:#ff5189,marker:#f09479'

function setProxy() {
        export http_proxy="http://127.0.0.1:7897"
        export https_proxy=$http_proxy
        export ftp_proxy=$http_proxy
        export all_proxy=$http_proxy
        export rsync_proxy=$http_proxy
        export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"
}

[ "$(tty)" = "/dev/tty1" ] && exec sway

if is_wsl; then
   cd $HOME    
fi

