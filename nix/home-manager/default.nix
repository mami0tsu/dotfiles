{
  config,
  pkgs,
  self,
  username,
  ...
}:
{
  home.username = username;

  # Home Manager の互換性を保つための状態バージョンを指定する
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    bat # v0.26.1
    coreutils # v9.8
    curl # v8.18.0
    delta # v0.18.2
    eza # v0.23.4
    findutils # v4.10.0
    gnugrep # v3.12
    gnused # v4.9
    gojq # v0.12.17
    # jq
    tree # v2.2.1
    ripgrep # v15.1.0

    awscli2 # v2.31.39
    docker # v28.5.2
    fzf # v0.67.0
    gh # v2.83.2
    ghq # v1.8.0
    git-secrets # v1.3.0
    go-task # v3.45.5
    neovim # v0.11.7
    starship # v1.24.2
    tree-sitter # v0.25.10
    zellij # v0.43.1

    deno # v2.6.10
    fnm # v1.38.1
    go # v1.25.7
    rustup # v1.28.2
    tenv # v4.8.3
    uv # v0.9.30
  ];

  programs.home-manager.enable = true;

  xdg.enable = true;

  programs.zsh = {
    enable = true;

    initContent = ''
      # 補完関数の読み込み
      autoload -Uz compinit && compinit -C

      # システム設定
      unsetopt correct
      setopt hist_reduce_blanks
      zstyle ':completion:*:default' menu select=1

      # 外部ツール初期化
      eval "$(fnm env --use-on-cd)"

      function ghq-fzf() {
        local src=$(ghq list | fzf --preview "bat --color=always --style=header,grid --line-range :80 $(ghq root)/{}/README.*")
        if [ -n "$src" ]; then
          BUFFER="cd $(ghq root)/$src"
          zle accept-line
        fi
        zle -R -c
      }
      zle -N ghq-fzf
      bindkey '^g' ghq-fzf
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
        src = pkgs.fetchFromGitHub {
          owner = "romkatv";
          repo = "zsh-defer";
          rev = "master";
          sha256 = "0m8xhzdqy2fbd1vj2vy95xjij4vz547i9lbdj6h794n2fc16yn9h";
        };
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
        src = pkgs.fetchFromGitHub {
          owner = "paulirish";
          repo = "git-open";
          rev = "master";
          sha256 = "1z0kw0kwrfh2rh0znc17bkm7w4c5vi6ynvhxvsq7naqfwydfvjvg";
        };
      }
    ];
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile = {
    "espanso".source = "${self}/espanso";
    "ghostty".source = "${self}/ghostty";
    "git".source = "${self}/git";
    "mise".source = "${self}/mise";
    "nvim".source = "${self}/nvim";
    "starship".source = "${self}/starship";
    "zellij".source = "${self}/zellij";
  };

  home.file = {
    ".brewfile".source = "${self}/brew/.brewfile";
    ".editorconfig".source = "${self}/.editorconfig";
  };
}
