" vim9script

let g:vista_icon_indent = ["╰─▸ ", "├─▸ "]
let g:vista_default_executive = 'coc'
let g:vista_fzf_preview = ['right:50%']

let g:vista_fold_toggle_icons = ['▼', '▶']
let g:vista#renderer#enable_icon = 1
let g:vista_echo_cursor_strategy = 'floating_win'
let g:vista#renderer#icons = {
            \"function": "\uf794",
            \"variable": "\uf71b",
            \}
let g:vista_executive_for = {
            \"cpp": "coc",
            \ "rust": "coc",
            \ "markdown": "toc",
            \ "python": "coc",
            \}

" Ensure you have installed some decent font to show these pretty symbols, then you can enable icon for the kind.
let g:vista_fzf_preview = ['right:50%']
" The default icons can't be suitable for all the filetypes, you can extend it as you wish.
"# <CR>          - jump to the tag under the cursor.
"# <2-LeftMouse> - Same as <CR>.
"# p             - preview the tag under the context via the floating window if it's avaliable.
"# s            - sort the symbol alphabetically or the location they are declared.
"# q             - close the vista window.

function NearestMethodOrFunction()
  return get(b:, 'vista_nearest_method_or_function', '')
endfunc

call airline#parts#define('vista', {'function': 'NearestMethodOrFunction'})
let g:airline_section_b = airline#section#create_left(['vista'])

autocmd VimEnter * call vista#RunForNearestMethodOrFunction()
nnoremap <silent> <F4> :<C-u>Vista!!<CR>
hi Pmenu ctermbg=NONE ctermfg=NONE cterm=NONE gui=NONE guifg=NONE guibg=#3b4253
