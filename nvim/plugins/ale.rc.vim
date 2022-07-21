let g:ale_linters = {
      \   'javascript': ['eslint'],
      \   'go': ['gofmt'],
      \}
let g:ale_fixers = {
      \   'javascript': ['prettier'],
      \   'typescript': ['prettier'],
      \   'markdown': ['prettier'],
      \   'go': ['gofmt'],
      \}

let g:ale_completion_enabled = 1
let g:ale_fix_on_save = 1
let g:ale_javascript_prettier_use_local_config = 1
let g:ale_set_highlights = 0
let g:ale_virtualtext_cursor = 1
