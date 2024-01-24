let g:asyncrun_rootmarks = ['.git', '.svn', '.root', '.project', '.hg', 'Cargo.toml']
let g:asyncrun_open=10
let g:asyncrun_save=1
noremap <silent><F5> :AsyncTask file-run  <CR>
noremap <silent><F9> :AsyncTask file-build<CR>
