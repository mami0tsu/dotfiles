" Basic settings {{{
if has('persistent_undo')
  set undodir=~/.vim/undo
  set undofile
  set undolevels=1000
endif

" Encode
set encoding=UTF-8
set shortmess+=c

" Set statusline
set laststatus=2

" Display line number
set nu

" Highlight a matching opening or closing parenthesis, square bracket or a curly brace
set showmatch

" Display ruler
set ruler

" Enable incsearch
set incsearch

" Switch on highlighting the last used search pattern
set hlsearch

" Display another buffer when current buffer isn't saved.
set hidden

" Do not create swap files
set noswapfile
" }}}

set signcolumn=yes

set termguicolors

command! -nargs=* T split | wincmd j | resize 20 | terminal <args>
autocmd TermOpen * startinsert
