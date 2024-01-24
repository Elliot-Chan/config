" vim9script

" # 保存自动格式化
augroup fmt
  autocmd!
  autocmd BufWritePre * undojoin | Neoformat
augroup END
