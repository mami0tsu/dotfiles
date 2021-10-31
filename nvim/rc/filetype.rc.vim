" FileType {{{
au BufNewFile,BufRead *.go set filetype=go
au BufNewFile,BufRead *.tf set filetype=terraform
au BufNewFile,BufRead *.yml set filetype=yaml
au BufNewFile,BufRead *.yaml set filetype=yaml
au BufNewFile,BufRead *.toml set filetype=toml
" }}}

" Indentation settings {{{
au Filetype go setlocal ts=4 sts=4 sw=4
au Filetype terraform setlocal ts=2 sts=2 sw=2
au Filetype yaml setlocal ts=2 sts=2 sw=2 et
" }}}
