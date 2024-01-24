
function! WindowNumber(...)
    let builder = a:1
    let context = a:2
    call builder.add_section('airline_b', '%{tabpagewinnr(tabpagenr())}')
    return 0
endfunction

call airline#add_statusline_func('WindowNumber')
call airline#add_inactive_statusline_func('WindowNumber')

function! MyLineNumber()
  return substitute(line('.'), '\d\@<=\(\(\d\{3\}\)\+\)$', ',&', 'g'). ' | '.
    \    substitute(line('$'), '\d\@<=\(\(\d\{3\}\)\+\)$', ',&', 'g')
endfunction

call airline#parts#define('linenr', {'function': 'MyLineNumber', 'accents': 'bold'})
   augroup vimrc
      " Auto rebuild C/C++ project when source file is updated, asynchronously
      autocmd BufWritePost *.c,*.cpp,*.h
                  \ let dir=expand('<amatch>:p:h') |
                  \ if filereadable(dir.'/Makefile') || filereadable(dir.'/makefile') |
                  \   execute 'AsyncRun -cwd=<root> make -j8' |
                  \ endif
      " Auto toggle the quickfix window
      autocmd User AsyncRunStop
                  \ if g:asyncrun_status=='failure' |
                  \   execute('call asyncrun#quickfix_toggle(8, 1)') |
                  \ else |
                  \   execute('call asyncrun#quickfix_toggle(8, 0)') |
                  \ endif
    augroup END

    " Define new accents
    function! AirlineThemePatch(palette)
      " [ guifg, guibg, ctermfg, ctermbg, opts ].
      " See "help attr-list" for valid values for the "opt" value.
      " http://vim.wikia.com/wiki/Xterm256_color_names_for_console_Vim
      let a:palette.accents.running = [ '', '', '', '', '' ]
      let a:palette.accents.success = [ '#00ff00', '' , 'green', '', '' ]
      let a:palette.accents.failure = [ '#ff0000', '' , 'red', '', '' ]
    endfunction
    let g:airline_theme_patch_func = 'AirlineThemePatch'


    " Change color of the relevant section according to g:asyncrun_status, a global variable exposed by AsyncRun
    " 'running': default, 'success': green, 'failure': red
    let g:async_status_old = ''
    function! Get_asyncrun_running()

      let async_status = g:asyncrun_status
      if async_status != g:async_status_old

        if async_status == 'running'
          call airline#parts#define_accent('asyncrun_status', 'running')
        elseif async_status == 'success'
          call airline#parts#define_accent('asyncrun_status', 'success')
        elseif async_status == 'failure'
          call airline#parts#define_accent('asyncrun_status', 'failure')
        endif

        let g:airline_section_x = airline#section#create(['asyncrun_status'])
        AirlineRefresh
        let g:async_status_old = async_status

      endif

      return async_status

    endfunction

    call airline#parts#define_function('asyncrun_status', 'Get_asyncrun_running')
    let g:airline_section_x = airline#section#create(['asyncrun_status'])

let g:airline_section_z = airline#section#create(['%3p%%: ', 'linenr', ':%3v'])

" let g:airline_theme = 'gruvbox'
" let g:airline_theme = 'ayu_mirage'
let g:airline_theme = 'onedark'
let g:airline_powerline_fonts = 1
" * enable/disable enhanced tabline. (c)
let g:airline#extensions#tabline#enabled = 1
" enable/disable displaying buffers with a single tab. (c)
" let g:airline#extensions#tabline#show_buffers = 1
" enable/disable displaying tabs, regardless of number. (c)
" let g:airline#extensions#tabline#show_tabs = 1
" always displaying number of tabs in the right side (c) >
" let g:airline#extensions#tabline#show_tab_count = 3


" let g:airline#extensions#tabline#show_tab_type = 1

" label
let g:airline#extensions#tabline#buf_label_first = 1
let g:airline#extensions#tabline#buffers_label = 'buffer'
let g:airline#extensions#tabline#tabs_label = 'tab'
"
" let g:airline#extensions#tabline#show_tab_nr = 0
"let g:airline#extensions#tabline#tab_nr_type = 0
"
" let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_sep = ''
let g:airline#extensions#tabline#left_alt_sep = ''
let g:airline#extensions#tabline#right_sep = ''
let g:airline#extensions#tabline#right_alt_sep = ''
" let g:airline#extensions#tabline#left_alt_sep = '|'

let g:airline#extensions#branch#prefix = '⤴'
"  ➔, ➥, ⎇
let g:airline#extensions#paste#symbol = 'ρ'

" let g:airline#extensions#tabline#formatter = 'default'
let g:airline#extensions#tabline#formatter = 'unique_tail'

let g:airline#extensions#tabline#buffer_nr_show = 0        "显示buffer编号
let g:airline#extensions#tabline#buffer_nr_format = '%s:'

let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep= ''
let g:airline_right_alt_sep = ''

let g:airline#extensions#tabline#buffer_idx_mode = 1
nmap <leader>1 <Plug>AirlineSelectTab1
nmap <leader>2 <Plug>AirlineSelectTab2
nmap <leader>3 <Plug>AirlineSelectTab3
nmap <leader>4 <Plug>AirlineSelectTab4
nmap <leader>5 <Plug>AirlineSelectTab5
nmap <leader>6 <Plug>AirlineSelectTab6
nmap <leader>7 <Plug>AirlineSelectTab7
nmap <leader>8 <Plug>AirlineSelectTab8
nmap <leader>9 <Plug>AirlineSelectTab9
nmap <leader>0 <Plug>AirlineSelectTab0
nmap <leader>- <Plug>AirlineSelectPrevTab
nmap <leader>+ <Plug>AirlineSelectNextTab
