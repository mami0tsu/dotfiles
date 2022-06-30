" Define keymap {{{
let mapleader = "\<Space>"

nnoremap <Leader>w :w<CR>

nnoremap U <C-r>

nnoremap <silent><Left> :bp<CR>
nnoremap <silent><Right> :bn<CR>

nnoremap gk :tabedit
nnoremap gj :tabclose<CR>
nnoremap gh gT
nnoremap gl gt

inoremap <silent> <C-[> <Esc>
vnoremap <silent> <C-[> <Esc>
tnoremap <silent> <C-[> <C-\><C-n>
" }}}
