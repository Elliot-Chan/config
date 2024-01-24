" "vim9script
" "
"
" " Install the following plugins first
" " vim-denops/denops.vim
" " Shougo/ddu.vim
" " Shougo/ddu-ui-ff
" " Shougo/ddu-source-file_rec
" " Shougo/ddu-kind-file
" " Shougo/ddu-filter-matcher_substring
"
" " Set common settings for all
" call ddu#custom#patch_global({
"     \     "ui": "ff",
"     \     "sourceOptions": {
"     \         "_": {
"     \             "matchers": ["matcher_substring"]
"     \         },
"     \     },
"     \ })
"
" " Prepare settings for use with DduNodeFiles
" call ddu#custom#patch_local("node-files", {
"     \     "sources": ["file_rec"],
"     \     "sourceParams": {
"     \         "file_rec": {
"     \             "ignoredDirectories": [".git", "node_modules"],
"     \         }
"     \     }
"     \ })
"
" " Prepare settings for use with DduWholeFiles
" call ddu#custom#patch_local("whole-files", {
"     \     "sources": ["file_rec"],
"     \     "sourceParams": {
"     \         "file_rec": {
"     \             "ignoredDirectories": [],
"     \         }
"     \     },
"     \     "sourceOptions": {
"     \         "file_rec": {
"     \             "maxItems": 50000
"     \         }
"     \     }
"     \ })
"
" " Set a Keymap (`e`) effective only in ddu-ui-ff
" autocmd FileType ddu-ff call s:ddu_ff_settings()
" function s:ddu_ff_settings() abort
"     nnoremap <buffer> e <Cmd>call ddu#ui#do_action('itemAction', {'name': 'open'})<CR>
" endfunction
"
" " Prepare commands to call ddu#start with each option set name
" command! DduNodeFiles call ddu#start({"name": "node-files", "sourceOptions": {"file_rec": {"path": getcwd()}}})
" command! DduWholeFiles call ddu#start({"name": "whole-files", "sourceOptions": {"file_rec": {"path": getcwd()}}})
