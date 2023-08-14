export LANG=ja_JP.UTF-8
export EDITOR=nvim
export VISUAL=nvim
export PATH="$PATH:$HOME/go/bin"

# History
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

setopt hist_ignore_alldups
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt share_history

unsetopt correct
autoload -Uz compinit && compinit
zstyle ':completion:*:default' menu select=1

export RTX_DATA_DIR=$HOME/.rtx
export RTX_CACHE_DIR=$RTX_DATA_DIR/cache
export RTX_CONFIG_FILE=$HOME/.config/rtx/rtx.toml
eval "$($HOME/bin/rtx activate zsh)"

export STARSHIP_CONFIG=$HOME/.config/starship/starship.toml
