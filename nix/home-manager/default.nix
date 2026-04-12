{
  config,
  pkgs,
  username,
  ...
}:
{
  home.username = username;

  # Home Manager の互換性を保つための状態バージョンを指定する
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    bat
    coreutils
    curl
    delta
    eza
    findutils
    gnugrep
    gnused
    gojq
    # jq
    tree
    ripgrep

    awscli2
    docker
    fzf
    gh
    ghq
    git-secrets
    go-task
    neovim
    sheldon
    starship
    tree-sitter
    zellij

    deno
    fnm
    go
    rustup
    tenv
    uv
  ];

  programs.home-manager.enable = true;

  # dotfiles のシンボリックリンク設定
  xdg.configFile = {
    # zsh
    "zsh".source = ../../zsh;
    # sheldon
    "sheldon".source = ../../sheldon;
    # starship
    "starship/starship.toml".source = ../../starship/starship.toml;

    # ghostty
    "ghostty".source = ../../ghostty;
    # git
    "git".source = ../../git;
    # mise
    "mise".source = ../../mise;
    # nvim
    "nvim".source = ../../nvim;
    # zellij
    "zellij".source = ../../zellij;
    # espanso
    "espanso".source = ../../espanso;
  };

  home.file = {
    # .zshenv (ZDOTDIR の設定に必要)
    ".zshenv".source = ../../zsh/.zshenv;
    # .brewfile
    ".brewfile".source = ../../brew/.brewfile;
    # .editorconfig
    ".editorconfig".source = ../../.editorconfig;
  };
}
