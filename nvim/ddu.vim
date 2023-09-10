" hook_source  {{{
call ddu#custom#patch_global(#{
    \     kindOptions: #{
    \         file: #{
    \             defaultAction: 'open',
    \         },
    \     },
    \ })
call ddu#custom#patch_local('ff', #{
    \     ui: 'ff',
    \     sourceOptions: #{
    \         file: #{
    \             matchers: ['matcher_substring'],
    \             columns: ['icon_filename'],
    \             path: t:->get('ddu_ui_ff_path', getcwd())
    \         },
    \     },
    \     uiParams: #{
    \         ff: #{
    \             split: 'floating',
    \         }
    \     },
    \ })
call ddu#custom#patch_local('filer', #{
    \     ui: 'filer',
    \     sourceOptions: #{
    \         file: #{
    \             columns: ['icon_filename'],
    \             path: t:->get('ddu_ui_filer_path', getcwd())
    \         },
    \     },
    \     uiParams: #{
    \         filer: #{
    \             previewFloating: v:true,
    \             previewHeight: '20',
    \             previewSplit: 'vertical',
    \             previewWidth: '&columns / 2',
    \             sort: 'filename',
    \             split: 'floating',
    \             winHeight: '20',
    \             winWidth: '&columns / 2',
    \         }
    \     },
    \ })
" }}}
