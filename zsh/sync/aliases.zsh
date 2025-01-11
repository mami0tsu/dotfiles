conditional_alias() {
  local src=$1
  local dst=$2
  local opts=$3
  if command -v "$dst" > /dev/null 2>&1; then
    alias "$src"="$dst $opts"
  fi
}

case "$OSTYPE" in
    darwin*)
        (( ${+commands[gdate]} )) && alias date='gdate'
        (( ${+commands[gls]} )) && alias ls='gls'
        (( ${+commands[gmkdir]} )) && alias mkdir='gmkdir'
        (( ${+commands[gcp]} )) && alias cp='gcp'
        (( ${+commands[gmv]} )) && alias mv='gmv'
        (( ${+commands[grm]} )) && alias rm='grm'
        (( ${+commands[gdu]} )) && alias du='gdu'
        (( ${+commands[ghead]} )) && alias head='ghead'
        (( ${+commands[gtail]} )) && alias tail='gtail'
        (( ${+commands[gsed]} )) && alias sed='gsed'
        (( ${+commands[ggrep]} )) && alias grep='ggrep'
        (( ${+commands[gfind]} )) && alias find='gfind'
        (( ${+commands[gdirname]} )) && alias dirname='gdirname'
        (( ${+commands[gxargs]} )) && alias xargs='gxargs'
    ;;
esac

conditional_alias 'cat' 'bat'
conditional_alias 'ls' 'eza' '-l -h --git --group-directories-first --time-style=long-iso'
conditional_alias 'tf' 'tofu'
conditional_alias 'v' 'nvim'
conditional_alias 'vim' 'nvim'
