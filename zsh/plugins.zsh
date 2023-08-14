# auto suggest
## https://github.com/zsh-users/zsh-autosuggestions
zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions

# syntax highlight
## https://github.com/zdharma/fast-syntax-highlighting
zinit ice wait lucid
zinit light zdharma/fast-syntax-highlighting

# github cli
## https://github.com/cli/cli
zinit ice wait lucid as"program" from"gh-r" pick"usr/bin/gh"
zinit light cli/cli

# git open
## https://github.com/paulirish/git-open
zinit ice wait lucid
zinit light paulirish/git-open

# bat
## https://github.com/sharkdp/bat
zinit ice wait lucid as"program" from"gh-r" mv"bat* -> bat" pick"bat/bat"
zinit light sharkdp/bat

# exa
## https://github.com/ogham/exa
zinit ice wait lucid as"program" from"gh-r" mv"bin -> exa" pick"exa/exa"
zinit light ogham/exa
