"vim9script

let g:floaterm_autoclose = 2
nnoremap   <silent>   <leader><F1>    :FloatermNew --height=0.6 --width=0.4 --wintype=float --name=floaterm1 --position=topleft --autoclose=2 <CR>
tnoremap   <silent>   <leader><F1>    <C-\><C-n>:FloatermNew<CR>
nnoremap   <silent>   <leader><F2>    :FloatermPrev<CR>
tnoremap   <silent>   <leader><F2>    <C-\><C-n>:FloatermPrev<CR>
nnoremap   <silent>   <leader><F3>    :FloatermNext<CR>
tnoremap   <silent>   <leader><F3>    <C-\><C-n>:FloatermNext<CR>
nnoremap   <silent>   <F12>   :FloatermToggle<CR>
tnoremap   <silent>   <F12>   <C-\><C-n>:FloatermToggle<CR>

autocmd User FloatermOpen :inoremap <C-x>: <C-w>N       
