" vim9script

let g:asyncrun_open = 6
" let g:asynctasks_term_pos = 'bottom'
let g:asynctasks_term_pos = 'floaterm'
let g:asynctasks_term_reuse = 1
let g:asynctasks_term_hidden = 1


noremap <silent><f6> :AsyncTask project-run<cr>
noremap <silent><f7> :AsyncTask project-build<cr>
