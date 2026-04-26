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

  xdg.configFile = {
    "espanso".source = "${self}/espanso";
    "ghostty".source = "${self}/ghostty";
    "git".source = "${self}/git";
    "mise".source = "${self}/mise";
    "nvim".source = "${self}/nvim";
    "sheldon".source = "${self}/sheldon";
    "starship".source = "${self}/starship";
    "zellij".source = "${self}/zellij";
    "zsh".source = "${self}/zsh";
  };

  home.file = {
    ".brewfile".source = "${self}/brew/.brewfile";
    ".editorconfig".source = "${self}/.editorconfig";
    ".zshenv".source = "${self}/zsh/.zshenv";
  };
}
