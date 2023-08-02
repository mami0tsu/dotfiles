" hook_source {{{
    call ddu#custom#patch_global(#{
        \   ui: 'filer',
        \   sources: [
        \     {
        \       'name': 'file',
        \       'params': {},
        \     },
        \   ],
        \   sourceOptions: #{
        \     _: #{
        \       columns: ['filename'],
        \     },
        \   },
        \   kindOptions: #{
        \     file: #{
        \       defaultAction: 'open',
        \     },
        \   },
        \   uiParams: #{
        \     filer: #{
        \       split: 'floating',
        \       sort: 'filename',
        \     }
        \   },
        \ })
" }}}
