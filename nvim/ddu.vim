" hook_source  {{{
call ddu#custom#patch_global(#{
    \     kindOptions: #{
    \         file: #{
    \             defaultAction: 'open',
    \         },
    \     },
    \ })
call ddu#custom#patch_local('rg', #{
    \     ui: 'ff',
    \     sourceOptions: #{
    \         rg: #{
    \             converters: ['converter_devicon'],
    \             matchers: [
    \                 "matcher_substring",
    \             ],
    \             volatile: v:true,
    \         },
    \     },
    \     sourceParams: #{
    \         rg: #{
    \             args: [
    \                 "--ignore-case",
    \                 "--column",
    \                 "--no-heading",
    \                 "--color",
    \                 "never",
    \             ],
    \         },
    \     },
    \     uiParams: #{
    \         ff: #{
    \             autoAction: #{ name: 'preview' },
    \             floatingBorder: 'single',
    \             filterFloatingPosition: 'top',
    \             filterSplitDirection: 'aboveleft',
    \             highlights: #{
    \                 floating: 'Normal',
    \                 floatingBorder: 'Normal',
    \             },
    \             previewFloating: v:true,
    \             previewFloatingBorder: 'single',
    \             previewHeight: '&lines / 2',
    \             previewSplit: 'vertical',
    \             previewWidth: '&columns / 2',
    \             prompt: '>',
    \             split: 'floating',
    \             startAutoAction: v:true,
    \             startFilter: v:true,
    \             splitDirection: 'aboveleft',
    \             winHeight: '&lines / 2',
    \             winWidth: '&columns',
    \         }
    \     },
    \     filterParams: #{
    \         matcher_substring: #{
    \             highlightMatched: 'Search',
    \         },
    \     },
    \ })
call ddu#custom#patch_local('ff', #{
    \     ui: 'ff',
    \     sourceOptions: #{
    \         file: #{
    \             converters: ['converter_devicon'],
    \             matchers: [
    \                 'matcher_relative',
    \                 'matcher_substring',
    \             ],
    \             path: t:->get('ddu_ui_ff_path', getcwd()),
    \         },
    \         file_rec: #{
    \             converters: ['converter_devicon'],
    \             matchers: [
    \                 'matcher_relative',
    \                 'matcher_substring',
    \             ],
    \             path: t:->get('ddu_ui_ff_path', getcwd()),
    \         },
    \         line: #{
    \             matchers: ['matcher_substring'],
    \         },
    \     },
    \     sourceParams: #{
    \         file_rec: #{
    \             ignoreDirectories: ['.git', '.terraform']
    \         },
    \     },
    \     uiParams: #{
    \         ff: #{
    \             autoAction: #{ name: 'preview' },
    \             floatingBorder: 'single',
    \             filterFloatingPosition: 'top',
    \             filterSplitDirection: 'aboveleft',
    \             highlights: #{
    \                 floating: 'Normal',
    \                 floatingBorder: 'Normal',
    \             },
    \             previewFloating: v:true,
    \             previewFloatingBorder: 'single',
    \             previewHeight: '&lines / 2',
    \             previewSplit: 'vertical',
    \             previewWidth: '&columns / 2',
    \             prompt: '>',
    \             split: 'floating',
    \             startAutoAction: v:true,
    \             startFilter: v:true,
    \             splitDirection: 'aboveleft',
    \             winHeight: '&lines / 2',
    \             winWidth: '&columns',
    \         }
    \     },
    \     filterParams: #{
    \         matcher_substring: #{
    \             highlightMatched: 'Search',
    \         },
    \     },
    \ })
call ddu#custom#patch_local('filer', #{
    \     ui: 'filer',
    \     sourceOptions: #{
    \         file: #{
    \             converters: ['converter_devicon'],
    \             path: t:->get('ddu_ui_filer_path', getcwd())
    \         },
    \     },
    \     uiParams: #{
    \         filer: #{
    \             floatingBorder: 'single',
    \             highlights: #{
    \                 floating: 'Normal',
    \                 floatingBorder: 'Normal',
    \             },
    \             previewFloating: v:true,
    \             previewFloatingBorder: 'single',
    \             previewHeight: '&lines / 2',
    \             previewSplit: 'vertical',
    \             previewWidth: '&columns / 2',
    \             sort: 'filename',
    \             sortTreesFirst: v:true,
    \             split: 'floating',
    \             winHeight: '&lines / 2',
    \             winWidth: '&columns',
    \         }
    \     },
    \ })
" }}}
