export RTX_DATA_DIR=$HOME/.rtx
export RTX_CACHE_DIR=$RTX_DATA_DIR/cache
export RTX_CONFIG_FILE=$HOME/.config/rtx/rtx.toml

export SHELDON_CONFIG_DIR="$HOME/.config/sheldon"
export SHELDON_CONFIG_FILE="$SHELDON_CONFIG_DIR/sheldon.toml"
eval "$(sheldon source)"
