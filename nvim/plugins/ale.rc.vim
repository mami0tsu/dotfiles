let g:ale_completion_enabled = 1

let g:ale_linters = {
      \   'javascript': ['eslint'],
      \   'python': ['flake8'],
      \   'go': ['gofmt'],
      \}
let g:ale_fixers = {
      \   'javascript': ['eslint'],
      \   'python': ['yapf'],
      \   'go': ['gofmt'],
      \}
let g:ale_fix_on_save = 1
let g:ale_virtualtext_cursor = 1
