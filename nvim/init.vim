let $CACHE = '~/.cache'->expand()
if !($CACHE->isdirectory())
    call mkdir($CACHE, 'p')
endif

" Load dein
if &runtimepath !~# '/dein.vim'
    let s:dein_dir = $CACHE .. '/dein/repos/github.com/Shougo/dein.vim'
    if !(s:dein_dir->isdirectory())
        execute '!git clone https://github.com/Shougo/dein.vim' s:dein_dir
    endif
    execute 'set runtimepath^=' .. s:dein_dir
endif

let g:dein#auto_recache = v:true

let g:dein#lazy_rplugins = v:true
let g:dein#install_progress_type = 'floating'
let g:dein#install_check_diff = v:true
let g:dein#enable_notification = v:true
let g:dein#install_check_remote_threshold = 24 * 60 * 60
let g:dein#auto_remote_plugins = v:false
let g:dein#install_copy_vim = v:true

let $BASE_DIR = '<sfile>'->expand()->fnamemodify(':h')
let s:path= $CACHE .. '/dein'
if dein#min#load_state(s:path)
    let g:dein#inline_vimrcs = [
        \ '$BASE_DIR/rc/filetype.rc.vim',
        \ '$BASE_DIR/rc/indent.rc.vim',
        \ '$BASE_DIR/rc/mappings.rc.vim',
        \ '$BASE_DIR/rc/options.rc.vim',
        \ ]

    call dein#begin(s:path, '<sfile>'->expand())

    call dein#load_toml('$BASE_DIR/dein.toml', #{ lazy: 0 })
    call dein#load_toml('$BASE_DIR/dein_lazy.toml', #{ lazy: 1 })
    call dein#load_toml('$BASE_DIR/ddc.toml', #{ lazy: 1 })
    call dein#load_toml('$BASE_DIR/ddu.toml', #{ lazy: 1 })
    call dein#load_toml('$BASE_DIR/neovim.toml', #{ lazy: 1 })

    call dein#end()
    call dein#save_state()
endif
