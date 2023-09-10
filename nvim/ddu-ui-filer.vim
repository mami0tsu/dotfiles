" hook_add = {{{
nnoremap <Space>f
    \ <Cmd>Ddu -name=filer file<CR>
" }}}

" ddu-filer = {{{
nnoremap <buffer> <Space>
    \ <Cmd>call ddu#ui#do_action('toggleSelectItem')<CR>
nnoremap <buffer> *
    \ <Cmd>call ddu#ui#do_action('toggleAllItems')<CR>
nnoremap <buffer> P
    \ <Cmd>call ddu#ui#do_action('togglePreview')<CR>
nnoremap <buffer> <Space>f
    \ <Cmd>call ddu#ui#do_action('quit')<CR>
nnoremap <buffer> q
    \ <Cmd>call ddu#ui#do_action('quit')<CR>
nnoremap <buffer> o
    \ <Cmd>call ddu#ui#do_action('expandItem',
    \ #{ mode: 'toggle' })<CR>
nnoremap <buffer> O
    \ <Cmd>call ddu#ui#do_action('expandItem',
    \ #{ maxLevel: -1 })<CR>
nnoremap <buffer> d
    \ <Cmd>call ddu#ui#do_action('itemAction',
    \ #{ name: 'delete' })<CR>
nnoremap <buffer> D
    \ <Cmd>call ddu#ui#do_action('itemAction',
    \ #{ name: 'trash' })<CR>
nnoremap <buffer> m
    \ <Cmd>call ddu#ui#do_action('itemAction',
    \ #{ name: 'move' })<CR>
nnoremap <buffer> r
    \ <Cmd>call ddu#ui#do_action('itemAction',
    \ #{ name: 'rename' })<CR>
nnoremap <buffer> p
    \ <Cmd>call ddu#ui#do_action('itemAction',
    \ #{ name: 'paste' })<CR>
nnoremap <buffer> K
    \ <Cmd>call ddu#ui#do_action('itemAction',
    \ #{ name: 'newDirectory' })<CR>
nnoremap <buffer> N
    \ <Cmd>call ddu#ui#do_action('itemAction',
    \ #{ name: 'newFile' })<CR>
nnoremap <buffer> h
    \ <Cmd>call ddu#ui#do_action('itemAction',
    \ #{ name: 'narrow', params: #{ path: '..' }})<CR>
nnoremap <buffer> ~
    \ <Cmd>call ddu#ui#do_action('itemAction',
    \ #{ name: 'narrow', params: #{ path: getcwd() } })<CR>
nnoremap <buffer> .
    \ <Cmd>call ddu#ui#do_action('updateOptions', #{
    \   sourceOptions: #{
    \     file: #{
    \       matchers: ToggleHidden('file'),
    \     },
    \   },
    \ })<CR>
nnoremap <buffer><expr> l
    \ ddu#ui#get_item()->get('isTree', v:false) ?
    \ "<Cmd>call ddu#ui#do_action('itemAction', #{ name: 'narrow' })<CR>" :
    \ "<Cmd>call ddu#ui#do_action('itemAction', #{ name: 'open' })<CR>"
nnoremap <buffer> c
    \ <Cmd>call ddu#ui#multi_actions([
    \   ['itemAction', #{ name: 'copy' }],
    \   ['clearSelectAllItems'],
    \ ])<CR>

function! ToggleHidden(name)
    const current = ddu#custom#get_current(b:ddu_ui_name)
    const source_options = current->get('sourceOptions', {})
    const source_options_name = source_options->get(a:name, {})
    const matchers = source_options_name->get('matchers', [])
    return matchers->empty() ? ['matcher_hidden'] : []
endfunction
" }}}
