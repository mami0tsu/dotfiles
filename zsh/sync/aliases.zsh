conditional_alias() {
  local src=$1
  local dst=$2
  local opts=$3
  if command -v "$dst" > /dev/null 2>&1; then
    alias "$src"="$dst $opts"
  fi
}

conditional_alias 'cat' 'bat'
conditional_alias 'ls' 'eza' '-l -h --git --group-directories-first --time-style=long-iso'
conditional_alias 'tf' 'tofu'
conditional_alias 'v' 'nvim'
conditional_alias 'vim' 'nvim'

alias cdr='cd $(git rev-parse --show-toplevel)'
