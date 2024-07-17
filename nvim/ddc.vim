" hook_source {{{
call ddc#custom#patch_global(#{
    \     ui: 'pum',
    \     autoCompleteEvents: [
    \         'InsertEnter',
    \         'TextChangedI',
    \         'TextChangedP',
    \         'CmdlineEnter',
    \         'CmdlineChanged',
    \         'TextChangedT',
    \     ],
    \     sources: [
    \         'around',
    \         'file',
    \         'rg',
    \     ],
    \     sourceOptions: #{
    \         _: #{
    \             ignoreCase: v:true,
    \             matchers: [
    \                 'matcher_head',
    \                 'matcher_length'
    \             ],
    \             sorters: [
    \                 'sorter_rank'
    \             ],
    \             converters: [
    \                 'converter_remove_overlap',
    \                 'converter_truncate_abbr',
    \             ],
    \             timeout: 1000,
    \         },
    \         around: #{
    \             mark: 'around',
    \         },
    \         buffer: #{
    \             mark: 'buffer',
    \         },
    \         cmdline: #{
    \             mark: 'cmdline',
    \             forceCompletionPattern: '\\S/\\S*|\\.\\w*',
    \         },
    \         input: #{
    \             mark: 'input',
    \             forceCompletionPattern: '\\S/\\S*',
    \             isVolatile: v:true,
    \         },
    \         line: #{
    \             mark: 'line',
    \             matchers: ['matcher_vimregexp'],
    \         },
    \         lsp: #{
    \             mark: 'lsp',
    \             forceCompletionPattern: '\\.\\w*|::\\w*|->\\w*',
    \             dup: 'force',
    \         },
    \         file: #{
    \             mark: 'file',
    \             isVolatile: v:true,
    \             minAutoCompleteLength: 1000,
    \             forceCompletionPattern: '\\S/\\S*',
    \         },
    \         shell-native: #{
    \             mark: 'shell',
    \             isVolatile: v:true,
    \             forceCompletionPattern: '\\S/\\S*',
    \         },
    \         rg: #{
    \             mark: 'rg',
    \             minAutoCompleteLength: 5,
    \             enabledIf: "finddir('.git', ';') != ''",
    \         },
    \     },
    \     sourceParams: #{
    \         buffer: #{
    \             requireSameFiletype: v:false,
    \             limitBytes: 50000,
    \             fromAltBuf: v:true,
    \             forceCollect: v:true,
    \         },
    \         file: #{
    \             filenameChars: '[:keyword:].',
    \         },
    \         shell-native: #{
    \             shell: 'zsh',
    \         },
    \     },
    \     postFilters: [
    \         'sorter_head',
    \     ],
    \ })

call ddc#custom#patch_filetype(
    \     [
    \         'bash',
    \         'sh',
    \         'zsh',
    \     ],
    \     #{
    \         sourceOptions: #{
    \             _: #{
    \                 keywordPattern: '[0-9a-zA-Z_./#:-]*',
    \             },
    \         },
    \         sources: [
    \             'around',
    \             'shell-native',
    \         ],
    \     },
    \ )

call ddc#custom#patch_filetype('deol', #{
    \     specialBufferCompletion: v:true,
    \     sourceOptions: #{
    \         _: #{
    \             keywordPattern: '[0-9a-zA-Z_./#:-]*',
    \         },
    \     },
    \     sources: [
    \         'around',
    \         'shell-native',
    \     ],
    \ })

call ddc#custom#patch_filetype(
    \     [
    \         'go',
    \         'terraform',
    \         'toml',
    \         'typescript',
    \         'yaml',
    \         'vim',
    \     ],
    \     #{
    \         sources: [
    \             'around',
    \             'lsp',
    \         ],
    \     },
    \ )

call ddc#enable_terminal_completion()

" Keymap for insert mode
inoremap <expr> <TAB>
    \ pum#visible() ? '<Cmd>call pum#map#insert_relative(+1)<CR>' :
    \ (col('.') <= 1 <Bar><Bar> getline('.')[col('.') - 2] =~# '\s') ?
    \ '<TAB>' : ddc#map#manual_complete()
inoremap <C-n>   <Cmd>call pum#map#select_relative(+1)<CR>
inoremap <C-p>   <Cmd>call pum#map#select_relative(-1)<CR>
inoremap <expr> j
    \ pum#entered() ?
    \ '<Cmd>call pum#map#insert_relative(+1)<CR>' : 'j'
inoremap <expr> k
    \ pum#entered() ?
    \ '<Cmd>call pum#map#insert_relative(-1)<CR>' : 'k'
inoremap <expr> q
    \ ddc#visible() ?
    \ '<Cmd>call ddc#hide()<CR>' : 'q'

call ddc#enable()

" }}}
