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

      # GitHub CLI の認証
      function _github_token() {
        setopt localoptions noxtrace
        local token

        if ! token="$(GH_TOKEN= GITHUB_TOKEN= command gh auth token --hostname github.com 2>/dev/null)" || [[ -z "$token" ]]; then
          print -u2 -- "GitHub CLI の認証を準備できません。保存済みの github.com 認証を読み出せませんでした。"
          print -u2 -- "通常のターミナルで GH_TOKEN= GITHUB_TOKEN= gh auth status --hostname github.com を確認し、必要なら GH_TOKEN= GITHUB_TOKEN= gh auth login --hostname github.com --web を実行してください。"
          return 1
        fi

        print -r -- "$token"
      }

      function _run_with_github_token() {
        setopt localoptions noxtrace
        local command_name="$1"
        local token
        shift

        if ! token="$(_github_token)"; then
          return 1
        fi

        GH_TOKEN="$token" GITHUB_TOKEN= command "$command_name" "$@"
      }

      function codex() {
        _run_with_github_token codex "$@"
      }

      function claude() {
        local argument

        for argument in "$@"; do
          case "$argument" in
            --settings | --settings=*)
              print -u2 -- "claude: --settings is managed by Home Manager"
              return 2
              ;;
          esac
        done

        _run_with_github_token claude --settings "${config.home.homeDirectory}/.claude/permissions.json" "$@"
      }

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
