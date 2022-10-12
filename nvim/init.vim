if &compatible
  set nocompatible
endif

let $CACHE = expand('~/.cache')
if !isdirectory($CACHE)
  call mkdir($CACHE, 'p')
endif

" Load dein
if &runtimepath !~# '/dein.vim'
  let s:dein_dir = $CACHE . '/dein/repos/github.com/Shougo/dein.vim'
  if !isdirectory(s:dein_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_dir
  endif
  execute 'set runtimepath^=' . s:dein_dir
endif

let g:dein#auto_recache = v:true

let g:dein#lazy_rplugins = v:true
let g:dein#install_progress_type = 'floating'
let g:dein#install_check_diff = v:true
let g:dein#enable_notification = v:true
let g:dein#install_check_remote_threshold = 24 * 60 * 60
let g:dein#auto_remote_plugins = v:false
let g:dein#install_copy_vim = v:true

let s:dein_plugin_dir= $CACHE . '/dein'
if dein#load_state(s:dein_plugin_dir)
  let s:base_dir = fnamemodify(expand('<sfile>'), ':h') . '/'
  let s:dein_toml = s:base_dir . 'dein.toml'
  let s:dein_lazy_toml = s:base_dir . 'dein_lazy.toml'
  let s:dein_ft_toml = s:base_dir . 'dein_ft.toml'
  let s:ddu_toml = s:base_dir . 'ddu.toml'

  call dein#begin(s:dein_plugin_dir, [
        \ expand('<sfile>'), s:dein_toml, s:dein_lazy_toml
        \ ])
  
  call dein#load_toml(s:dein_toml, {'lazy': 0})
  call dein#load_toml(s:dein_lazy_toml, {'lazy': 1})
  call dein#load_toml(s:ddu_toml, {'lazy': 1})
  
  call dein#end()
  call dein#save_state()
endif

source ~/.config/nvim/rc/filetype.rc.vim
source ~/.config/nvim/rc/indent.rc.vim
source ~/.config/nvim/rc/mappings.rc.vim
source ~/.config/nvim/rc/options.rc.vim
