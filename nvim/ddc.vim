" hook_source {{{
  call ddc#custom#patch_global('sources',
    \ ['around', 'file', 'rg'],
    \ )
  call ddc#custom#patch_global('sourceOptions', #{
    \   _: #{
    \     ignoreCase: v:true,
    \     matchers: ['matcher_head', 'matcher_length'],
    \     sorters: ['sorter_rank'],
    \     converters: [
    \       'converter_remove_overlap', 'converter_truncate_abbr',
    \     ],
    \   },
    \   around: #{
    \     mark: 'A',
    \   },
    \   nvim-lsp: #{
    \     mark: 'lsp',
    \     forceCompletionPattern: '\.\w*|:\w*|->\w*',
    \     dup: 'force,'
    \   },
    \ })

  if has('nvim')
    call ddc#custom#patch_filetype(
      \ ['go', 'terraform'], 'sources',
      \ ['around', 'nvim-lsp']
      \ )
  endif

  call ddc#custom#patch_global('autoCompleteEvents', [
      \ 'InsertEnter', 'TextChangedI', 'TextChangedP',
      \ 'CmdlineEnter', 'CmdlineChanged', 'TextChangedT',
      \ ])
  call ddc#custom#patch_global('ui', 'pum')

  inoremap <expr> <TAB>
        \ pum#visible() ? '<Cmd>call pum#map#insert_relative(+1)<CR>' :
        \ (col('.') <= 1 <Bar><Bar> getline('.')[col('.') - 2] =~# '\s') ?
        \ '<TAB>' : ddc#map#manual_complete()
  inoremap <S-Tab> <Cmd>call pum#map#insert_relative(-1)<CR>
  inoremap <C-n>   <Cmd>call pum#map#select_relative(+1)<CR>
  inoremap <C-p>   <Cmd>call pum#map#select_relative(-1)<CR>
  inoremap <expr> j
        \ pum#entered() ?
        \ '<Cmd>call pum#map#insert_relative(+1)<CR>' : 'j'
  inoremap <expr> k
        \ pum#entered() ?
        \ '<Cmd>call pum#map#insert_relative(-1)<CR>' : 'k'

  call ddc#enable()
" }}}
