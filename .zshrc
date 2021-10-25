# Starship
eval "$(starship init zsh)"

# Language encoding
export LANG=ja_JP.UTF-8

# Golang
export GOPATH=$(go env GOPATH)
export PATH=$PATH:$GOPATH/bin

# Turn off auto correct
unsetopt correct

# History
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

### Added by Zinit's installer
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
### End of Zinit's installer chunk

# Autocomplete
zinit light zsh-users/zsh-autosuggestions
autoload -Uz compinit
compinit
zstyle ':completion:*:default' menu select=1

# Syntax highlight
zinit light zdharma/fast-syntax-highlighting

# alias
alias terraform='docker container run --rm --name terraform --mount type=bind,source=$(pwd),target=/terraform -w /terraform --env-file .env hashicorp/terraform:1.0.9'
