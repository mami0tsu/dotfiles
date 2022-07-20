" Define keymap {{{
let mapleader = "\<Space>"

nnoremap <Leader>w :w<CR>

nnoremap U <C-r>

"------------------------------
" Window
"------------------------------
" Split window
nnoremap ws :split<CR><C-w>w
nnoremap wv :vsplit<CR><C-w>w

" Move window
nnoremap ww <C-w>w
nnoremap wh <C-w>h
nnoremap wk <C-w>k
nnoremap wj <C-w>j
nnoremap wl <C-w>l

" Resize window
nnoremap <C-w><Left> <C-w><
nnoremap <C-w><Right> <C-w>>
nnoremap <C-w><Up> <C-w>+
nnoremap <C-w><Down> <C-w>-


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
