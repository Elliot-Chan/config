"vim9script
let g:which_key_map = {}
let g:which_key_map.b = {
            \ 'name': '+buffer',
            \ '1': ['<Plug>AirlineSelectTab1', 'buffer1'],
            \ '2': ['<Plug>AirlineSelectTab2', 'buffer2'],
            \ '3': ['<Plug>AirlineSelectTab3', 'buffer3'],
            \ '4': ['<Plug>AirlineSelectTab4', 'buffer4'],
            \ '5': ['<Plug>AirlineSelectTab5', 'buffer5'],
            \ '6': ['<Plug>AirlineSelectTab6', 'buffer6'],
            \ '7': ['<Plug>AirlineSelectTab6', 'buffer7'],
            \ '8': ['<Plug>AirlineSelectTab8', 'buffer8'],
            \ '9': ['<Plug>AirlineSelectTab9', 'buffer9'],
            \ 'd': ['bd', 'delete-buffer'],
            \ 'f': ['bfirst', 'first-buffer'],
            \ 'h': ['Startify', 'home-buffer'],
            \ 'l': ['blast', 'last-buffer'],
            \ 'n': ['bnext', 'next-buffer'],
            \ 'p': ['bprevious', 'previous-buffer'],
            \ '?': ['Buffers', 'fzf-buffer'],
            \ }

let g:which_key_map.c = {
            \ 'name': 'Comment',
            \ 't': ['<Plug>NERDCommenterToggle', 'toggle'],
            \ 'c': ['<Plug>NERDCommenterComment', 'comment'],
            \ 'n': ['<Plug>NERDCommenterNested', 'nest'],
            \ 'm': ['<Plug>NERDCommenterMinimal', 'minimal'],
            \ 'i': ['<Plug>NERDCommenterInvert', 'invert'],
            \ 's': ['<Plug>NERDCommenterSexy', 'pretty'],
            \ 'y': ['<Plug>NERDCommenterYank', 'yanked first'],
            \ '$': ['<Plugg>NERDCommenterToEol', 'end'],
            \ 'A': ['<Plug>NERDCommenterAltDelims', 'alternative'],
            \ 'a': ['<Plug>NERDCommenterAppend', 'append'],
            \ 'u': ['<Plug>NERDCommenterUncomment', 'uncomment'],
            \ }
let g:which_key_map.F = {
            \ 'name': 'FZF',
            \ }
let g:which_key_map.l = {
            \ 'name': '+lsp',
            \ 'f': [':Neoformat', 'formatting'],
            \ 'g': {
                \ 'name': '+goto',
                \ 'd': ['<Plug>(coc-definition)', 'Definitions'],
                \ 'D': ['<Plug>(coc-declaration)', 'Declaration'],
                \ 'i': ['<Plug>(coc-implementation)', 'Implementation'],
            \ },
            \ 'h': ['CocAction("showOutcomingCalls")', 'Show Outcome Call Hieraychy'],
            \ 'H': ['CocAction("showIncomingCalls")', 'Show Income Call Hieraychy'],
            \ 'l': {
                \ 'name': 'CocList',
                \ 'c': [':CocList commands', 'Commands'],
                \ 'd': [':CocList diagnostic', 'Diagnostics'],
                \ 'o': ['CocList outline', 'document symbol'],
                \ 's': [':CocList -I symbols', 'workspace-symbol'],
                \ },
            \ 'r': ['<Plug>(coc-references)', 'references'],
            \ 'R': ['<Plug>(coc-rename)', 'Rename'],
            \ }
let g:which_key_map.t = {
            \ 'name': '+toggle',
            \ 'g': [':call ToggleGitLens()', 'git lens'],
            \ 'm': ['<Plug>MarkdownPreviewToggle', 'markdown preview'],
            \ }
let g:which_key_map.w = {
            \ 'name': '+windows',
            \ 'd': ['<C-W>c', 'delete-window'],
            \ '-': ['<C-W>s', 'split-window-below'],
            \ '>': ['<C-W>v', 'split-window-right'],
            \ '2': ['<C-W>v', 'layout-double-columns'],
            \ 'h': ['<C-W>h', 'window-left'],
            \ 'j': ['<C-W>j', 'window-below'],
            \ 'l': ['<C-W>l', 'window-right'],
            \ 'k': ['<C-W>k', 'window-up'],
            \ 'H': ['<C-W>5<', 'expand-window-left'],
            \ 'J': [':resize +5', 'expand-window-below'],
            \ 'L': ['<C-W>5>', 'expand-window-right'],
            \ 'K': [':resize -5', 'expand-window-up'],
            \ '|': ['<C-W>|', 'balance-window vertical'],
            \ '=': ['<C-W>=', 'balance-window horizon'],
            \ '_': ['<C-W>_', 'balance-window'],
            \ 's': ['<C-W>s', 'split-window-below'],
            \ 'v': ['<C-W>v', 'split-window-below'],
            \ '?': ['Windows', 'fzf-window'],
            \ }

let g:which_key_use_floating_win = 1
let g:which_key_floating_relative_win = 1
let g:which_key_floating_opts = {
            \ 'col': '-2',
            \ 'row': '0',
            \ 'height': '0',
            \ 'width': '100'
            \ }

nnoremap <silent> <localleader> :<c-u>WhichKey '<Space>'<CR>
vnoremap <silent> <localleader> :<c-u>WhichKeyVisual '<Space>'<CR>
let g:which_key_exit = "\<Space>"
call which_key#register('<Space>', "g:which_key_map")


hi WhichKeyFloating ctermfg=255 ctermbg=255 cterm=NONE guifg=#000000 guibg=#4b5263
" hi WhichKeyFloating ctermbg=BLACK ctermfg=BLACK
" autocmd ColorScheme gruvbox highlight WhichKeyFloating ctermbg=NONE ctermfg=NONE cterm=NONE 
" autocmd ColorScheme onehalfdark  highlight NormalFloat  ctermbg=none ctermfg=NONE
" hi WhichKeyFloat ctermfg=40 ctermbg=44 cterm=NONE guifg=#282c34 guibg=NONE
