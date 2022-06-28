# Language Encoding
export LANG=ja_JP.UTF-8

# History
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

setopt hist_ignore_alldups
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt share_history

# Zinit
## https://github.com/zdharma-continuum/zinit
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Key Bind
## https://github.com/jeffreytse/zsh-vi-mode
zinit ice wait lucid depth=1
zinit light jeffreytse/zsh-vi-mode

# Autocomplete
unsetopt correct
zinit light zsh-users/zsh-autosuggestions
autoload -Uz compinit && compinit
zstyle ':completion:*:default' menu select=1

# Syntax Highlight
zinit light zdharma/fast-syntax-highlighting

# Prompt
zinit ice wait lucid as"command" from"gh-r" \
    atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
    atpull"%atclone" src"init.zsh"
zinit light starship/starship

# Plugin
## https://github.com/paulirish/git-open
zinit light paulirish/git-open

## https://github.com/sharkdp/bat
zinit ice wait lucid as"program" from"gh-r" mv"bat* -> bat" pick"bat/bat"
zinit light sharkdp/bat

## https://github.com/ogham/exa
zinit ice wait lucid as"program" from"gh-r" mv"bin -> exa" pick"exa/exa"
zinit light ogham/exa

# Alias
alias cat='bat'
alias ls='exa -l -a -h --git'
alias vim='nvim'
