export MISE_ENV_FILE=.env
eval "$(/opt/homebrew/bin/mise activate zsh)"

export SHELDON_CONFIG_DIR="$HOME/.config/sheldon"
export SHELDON_CONFIG_FILE="$SHELDON_CONFIG_DIR/sheldon.toml"
eval "$(sheldon source)"
