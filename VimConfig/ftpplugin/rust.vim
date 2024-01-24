vim9script

g:rustfmt_autosave = 1

vnoremap <leader>ft :RustFmtRange<CR>
nnoremap <leader>ft :RustFmt<CR>

nnoremap <M-r> :RustRun<CR>
nnoremap <M-t> :RustTest<CR>

