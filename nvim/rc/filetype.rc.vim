" FileType {{{
au BufNewFile,BufRead *.go set filetype=go
au BufNewFile,BufRead *.lua set filetype=lua
au BufNewFile,BufRead *.md set filetype=markdown
au BufNewFile,BufRead *.tf set filetype=terraform
au BufNewFile,BufRead *.ts set filetype=typescript
au BufNewFile,BufRead *.tsx set filetype=typescript
au BufNewFile,BufRead *.yml set filetype=yaml
au BufNewFile,BufRead *.yaml set filetype=yaml
au BufNewFile,BufRead *.toml set filetype=toml
au BufNewFile,BufRead *.vim set filetype=vim
au BufNewFile,BufRead Dockerfile* set filetype=dockerfile
" }}}

" Indentation settings {{{
au Filetype go setlocal ts=4 sts=4 sw=4
au Filetype lua setlocal ts=2 sts=2 sw=2
au Filetype terraform setlocal ts=2 sts=2 sw=2
au Filetype typescript setlocal ts=2 sts=2 sw=2
au Filetype toml setlocal ts=2 sts=2 sw=2
au Filetype yaml setlocal ts=2 sts=2 sw=2 et
au Filetype vim setlocal ts=4 sts=4 sw=4
" }}}
