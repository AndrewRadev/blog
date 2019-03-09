runtime! projects/ruby.vim

silent AckIgnore _site/

augroup project
  autocmd!

  autocmd FileType css setlocal sw=4
  autocmd FileType scss setlocal sw=4
augroup END
