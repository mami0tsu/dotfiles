" hook_add = {{{
nnoremap <Space>g <Cmd>Ddu
    \ -name=rg rg
    \ <CR>
nnoremap <Space>s <Cmd>Ddu
    \ -name=ff file_rec
    \ <CR>
nnoremap / <Cmd>Ddu
    \ -name=ff line
    \ <CR>
" }}}

" ddu-ff {{{
nnoremap <buffer> <Space>
    \ <Cmd>call ddu#ui#do_action('toggleSelectItem')<CR>
nnoremap <buffer> *
    \ <Cmd>call ddu#ui#do_action('toggleAllItems')<CR>
nnoremap <buffer> P
    \ <Cmd>call ddu#ui#do_action('togglePreview')<CR>
nnoremap <buffer> <Space>g
    \ <Cmd>call ddu#ui#do_action('quit')<CR>
nnoremap <buffer> <Space>s
    \ <Cmd>call ddu#ui#do_action('quit')<CR>
nnoremap <buffer> q
    \ <Cmd>call ddu#ui#do_action('quit')<CR>
nnoremap <buffer> i
    \ <Cmd>call ddu#ui#do_action('openFilterWindow')<CR>
nnoremap <buffer> <CR>
    \ <Cmd>call ddu#ui#do_action('itemAction')<CR>
nnoremap <buffer> N
    \ <Cmd>call ddu#ui#do_action('itemAction',
    \ #{ name: 'newFile' })<CR>
nnoremap <buffer> p
    \ <Cmd>call ddu#ui#do_action('previewPath')<CR>
nnoremap <buffer> o
    \ <Cmd>call ddu#ui#do_action('expandItem',
    \ #{ mode: 'toggle' })<CR>
nnoremap <buffer> e
    \ <Cmd>call ddu#ui#do_action('itemAction',
    \ ddu#ui#get_item()->get('action', {})->get('isTree', v:false) ?
    \ #{ name: 'narrow' } : #{ name: 'open' })<CR>
nnoremap <buffer> y
    \ <Cmd>call ddu#ui#do_action('itemAction', #{ name: 'yank' })<CR>
nnoremap <buffer> g
    \ <Cmd>call ddu#ui#do_action('itemAction', #{ name: 'grep' })<CR>
" }}}

" ddu-ff-filter {{{
inoremap <buffer> <CR>
    \ <Esc><Cmd>call ddu#ui#do_action('closeFilterWindow')<CR>
nnoremap <buffer> <CR>
    \ <Cmd>call ddu#ui#do_action('closeFilterWindow')<CR>
nnoremap <buffer> q
    \ <Cmd>call ddu#ui#do_action('closeFilterWindow')<CR>
" }}}
