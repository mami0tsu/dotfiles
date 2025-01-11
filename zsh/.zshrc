# Zsh
export HISTFILE="$XDG_STATE_HOME/zsh_history"
export HISTSIZE=1000000
export SAVEHIST=1000000

setopt hist_ignore_alldups # 履歴内の古い重複エントリを削除する
setopt hist_reduce_blanks  # 履歴に余分な空白を記録しない
setopt hist_save_no_dups   # ファイル保存時に重複する履歴を記録しない
setopt share_history       # 複数のセッション間で履歴を共有する

unsetopt correct # コマンド入力補正機能を無効化する

zstyle ':completion:*:default' menu select=1 # 補完機能を有効化する

# mise
export MISE_ENV_FILE=.env
eval "$(/opt/homebrew/bin/mise activate zsh)"

# Sheldon
eval "$(sheldon source)"
