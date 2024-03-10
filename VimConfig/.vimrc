vim9script
#打开文件跳转至上次退出位置
if has("autocmd")
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

#Set Dein base path (required)
# let g:dein_base = '/home/elliot/.local/share/dein'

# Set Dein source path (required)
# g:dein_src = '/home/elliot/.local/share/dein/repos/github.com/Shougo/dein.vim'
# var g:dein_src = "/home/elliot/.local/share/dein/repos/github.com/Shougo/dein.vim"

#Set Dein runtime path (required)
# execute 'set runtimepath+=' .. g:dein_src
# Call Dein initialization (required)
# call dein#begin(g:dein_base)
if &compatible
  set nocompatible
endif
filetype off
#" append to runtime path
set rtp+=/usr/share/vim/vimfiles
#" initialize dein, plugins are installed to this directoryen
call dein#begin(expand('~/.cache/dein'))

#call dein#add(g:dein_src)

#Dein 辅助插件
call dein#add('https://wsdjeg.net/git/dein-ui.vim/')
# call dein#add('wsdjeg/dein-ui.vim')
call dein#add('haya14busa/dein-command.vim')

#文件浏览器
# call dein#add('vim-denops/denops.vim')
# call dein#add('Shougo/ddu.vim')
# call dein#add('Shougo/ddu-ui-ff')
# call dein#add('Shougo/ddu-kind-file')
# call dein#add('Shougo/ddu-filter-matcher_substring')
# call dein#add('Shougo/ddu-source-file')
# call dein#add('Shougo/ddu-source-file_rec')
# call dein#add('Shougo/ddu-source-buffer')
# call dein#add('Shougo/ddu-commands.vim')
# call dein#add('matsui54/denops-popup-preview.vim')
# call dein#add('Shougo/defx.nvim')
# call dein#add('kristijanhusak/defx-icons')

#if !has('nvim')
  #call dein#add('roxma/nvim-yarp')
  #call dein#add('roxma/vim-hug-neovim-rpc')
#endif

call dein#add('easymotion/vim-easymotion')


#Your plugins go here:
#call dein#add('Shougo/neosnippet.vim')
#call dein#add('Shougo/neosnippet-snippets')

#语言自动完成
call dein#add('neoclide/coc.nvim', { 'merged': 0, 'rev': 'release' })
# call dein#add('neoclide/coc.nvim', { 'merged': 0, 'rev': 'master', 'build': 'npm ci' })

#代码格式化
call dein#add('sbdchd/neoformat')

#模糊查找
#" ./install --all so the interactive script doesn't block
#you can check the other command line options  in the install file
call dein#add('junegunn/fzf', { 'build': './install --all', 'merged': 0 })
call dein#add('junegunn/fzf.vim', { 'depends': 'fzf' })

#成对修改环绕
call dein#add('tpope/vim-surround')


##buffer管理
call dein#add('jeetsukumaran/vim-buffergator')
##标签浏览器
call dein#add('liuchengxu/vista.vim')

##代码注释
call dein#add('preservim/nerdcommenter')

#括号补全
##call dein#add('Eliot00/auto-pairs')
call dein#add('jiangmiao/auto-pairs')
#主题
call dein#add('morhetz/gruvbox')
call dein#add('liuchengxu/space-vim-dark')
#状态栏

# call dein#add('liuchengxu/eleline.vim')
# set laststatus=2
call dein#add('vim-airline/vim-airline')
call dein#add('vim-airline/vim-airline-themes')
#indent缩进彩虹
#call dein#add('adi/vim-indent-rainbow')
#g:rainbow_colors_black = [ 234, 235, 236, 237, 238, 239 ]
#g:rainbow_colors_color = [ 226, 192, 195, 189, 225, 221 ]
# togglerb#map("<LocalLeader>c")
#rainbow#enable()
# indent 缩进线
call dein#add('Yggdroot/indentLine')
g:indentLine_char_list = ['|', '¦', '┆', '┊']
# g:indentLine_setColors = 0
# autocmd! VimEnter * :IndentLinesDisable
autocmd! BufNew,BufCreate,BufAdd,BufEnter * :IndentLinesEnable
# 彩虹括号
call dein#add('luochen1990/rainbow')
g:rainbow_active = 0
# 浮动窗口
call dein#add('voldikss/vim-floaterm')
call dein#add('windwp/vim-floaterm-repl', { 'depends': 'vim-floaterm' })
# 异步运行
call dein#add('skywind3000/asyncrun.vim')
# 异步任务
call dein#add('skywind3000/asynctasks.vim')

# rust支持
call dein#add('rust-lang/rust.vim')

# git支持
call dein#add('Eliot00/git-lens.vim')

# 显示快捷键
call dein#add('liuchengxu/vim-which-key')

# 开始屏幕
call dein#add('mhinz/vim-startify')

# 通知
call dein#add('igbanam/vim-notify')

# python-repl
call dein#add('sillybun/vim-repl')

# markdown 预览
call dein#add('skanehira/preview-markdown.vim')
g:preview_markdown_auto_update = 1

# 主题设置
call dein#add('mhartington/oceanic-next')
call dein#add('sonph/onehalf', { 'rtp': 'vim' })
call dein#add('kristijanhusak/vim-hybrid-material')

# snippets
call dein#add('SirVer/ultisnips')
call dein#add('honza/vim-snippets')

# Finish Dein initialization (required)
call dein#end()

# Uncomment if you want to install not-installed plugins on startup.
if dein#check_install()
    call dein#install()
endif
filetype plugin on
# leader key
g:maplocalleader = "\<Space>"
g:mapleader = ','

if exists('+termguicolors')
  # &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  # &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif
set background=dark
# 与 vi 的兼容性设置
set nocompatible

# 记录 N 条命令和匹配记录
set history=1000

# 行号和当前光标位置以及命令显示
set nu
set ruler
set showcmd

# 在状态行上显示补全匹配
set wildmenu
set wildoptions=pum

# 使 <Esc> 键生效更快
set ttimeout
set ttimeoutlen=100

# 如果末行被截短，显示 @@@而不是隐藏整行
set display=truncate

# 1. 查找时不循环跳转，2. 输入部分查找模式时显示相应的匹配点，3. 高亮显示匹配字符，4. 高亮显示括号匹配
set nowrapscan
set incsearch
set hls
set showmatch

# 不把 0 开头的字符识别成八进制数
set nrformats-=octal

# 统一缩进为 4 空格
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4


# 为 C 程序设置自动缩进
set cindent
set autoindent
set smartindent

# 同步主选区 #* 寄存器与匿名寄存器##
# set clipboard=unnamed

# 同步剪切板寄存器 #+ 与匿名寄存器##
set clipboard=unnamedplus

# fencview
set encoding=utf8
# set langmenu=zh_CN.UTF-8
# language message zh_CN.UTF-8
set langmenu=en_US.UTF-8
language message en_US.UTF-8
# set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1
set fileencodings=utf-8,cp936,gb18030,big5,euc-jp,latin1

# 修改 vim 的颜色
# set t_Co=256

# 搜索词全小写时忽略大小写，至少有一个大写字母时，进行大小写匹配
set ignorecase smartcase

# 光标所在行列高亮
# set cursorcolumn
set cursorline
set laststatus=2

# Ward off unexpected things that your distro might have made, as
# well as sanely reset options when re-sourcing .vimrc
set nocompatible

# 文件探测和语法高亮
filetype plugin indent on
syntax on

# vista默认执行命令
g:vista_default_executive = 'coc'

function KillAllFloaterm() abort
    for bufnr in floaterm#buflist#gather()
      call floaterm#terminal#kill(bufnr)
    endfor
    return
endfunction

# autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 | call KillAllFloaterm() | quit | endif
# autocmd BufEnter * if winnr('$') == 1 | call KillAllFloaterm() | quit | endif
colorscheme onehalfdark
# colorscheme hybrid_material
# colorscheme gruvbox
# colorscheme OceanicNext
# hi Comment cterm = italic
# g:airline_theme = "deus"
