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
}
