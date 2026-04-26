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
    bat            # v0.26.1
    coreutils      # v9.8
    curl           # v8.18.0
    delta          # v0.18.2
    eza            # v0.23.4
    findutils      # v4.10.0
    gnugrep        # v3.12
    gnused         # v4.9
    gojq           # v0.12.17
    # jq
    tree           # v2.2.1
    ripgrep        # v15.1.0

    awscli2        # v2.31.39
    docker         # v28.5.2
    fzf            # v0.67.0
    gh             # v2.83.2
    ghq            # v1.8.0
    git-secrets    # v1.3.0
    go-task        # v3.45.5
    neovim         # v0.11.7
    sheldon        # v0.8.5
    starship       # v1.24.2
    tree-sitter    # v0.25.10
    zellij         # v0.43.1

    deno           # v2.6.10
    fnm            # v1.38.1
    go             # v1.25.7
    rustup         # v1.28.2
    tenv           # v4.8.3
    uv             # v0.9.30
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
