{
  config,
  pkgs,
  self,
  ...
}:
let
  localPackages = self.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    initContent = ''
      # 補完関数の読み込み
      autoload -Uz compinit && compinit -C

      # システム設定
      unsetopt correct
      setopt hist_reduce_blanks
      zstyle ':completion:*:default' menu select=1

      # 外部ツール初期化
      eval "$(fnm env --use-on-cd)"
      eval "$(git-wt --init zsh)"

      # ghq wrapper
      function ghq() {
        if (( $# > 0 )); then
          command ghq "$@"
          return
        fi

        local ghq_root selected
        ghq_root="$(command ghq root)"

        selected="$(
          command ghq list --full-path |
            roots --root-file .git/config --root-file main.tf --depth 5 |
            while IFS= read -r path; do
              print -r -- "''${path#''${ghq_root}/}"$'\t'"''${path}"
            done |
            fzf --height 40% --reverse --delimiter=$'\t' --with-nth=1 |
            cut -f2
        )"

        [[ -n "$selected" ]] && cd -- "$selected"
      }
    '';

    history = {
      path = "${config.xdg.stateHome}/zsh_history";
      size = 1000000;
      save = 1000000;
      share = true;
      ignoreAllDups = true;
      saveNoDups = true;
    };

    sessionVariables = {
      LANG = "ja_JP.UTF-8";
      EDITOR = "nvim";
      GOPATH = "${config.xdg.dataHome}/go";
      TENV_AUTO_INSTALL = "true";
      FZF_DEFAULT_OPTS = "--bind 'ctrl-k:up,ctrl-j:down,ctrl-n:down,ctrl-p:up'";
    };

    shellAliases = {
      cat = "bat";
      ls = "eza -l -h --git --group-directories-first --time-style=long-iso";
      tf = "tofu";
      v = "nvim";
      vim = "nvim";
      cdr = "cd $(git rev-parse --show-toplevel)";
    };

    plugins = [
      {
        name = "zsh-defer";
        src = localPackages.zsh-defer-src;
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions.src;
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting.src;
      }
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions.src;
      }
      {
        name = "git-open";
        src = localPackages.git-open-src;
      }
    ];
  };
}
