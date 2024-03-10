let g:startify_files_number = 8
let g:startify_list_order = [
      \ ['   Most recently used files in the current directory:'],
      \ 'dir',
      \ ['   Most recently used files:'],
      \ 'files',
      \ ['   These are my sessions:'],
      \ 'sessions',
      \ ['   These are my bookmarks:'],
      \ 'bookmarks',
      \ ]
let g:startify_bookmarks = [ {'c': '~/.vimrc'},  {'z': '~/.zshrc'} ]
let g:startify_update_oldfiles = 1
" let g:startify_disable_at_vimenter = 1
let g:startify_session_autoload = 1
let g:startify_session_persistence = 1
let g:startify_session_delete_buffers = 0
let g:startify_change_to_dir = 1
"let g:startify_change_to_vcs_root = 0  " vim-rooter has same feature
let g:startify_skiplist = [
      \ 'COMMIT_EDITMSG',
      \ escape(fnamemodify(resolve($VIMRUNTIME), ':p'), '\') .'doc',
      \ 'bundle/.*/doc',
      \ ]
" let g:startify_custom_header = startify#pad(split(system('drawascii "GENSHIN" future_7'), '\n'))
