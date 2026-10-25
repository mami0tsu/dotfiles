{
  pkgs,
  self,
  ...
}:
let
  localPackages = self.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = with pkgs; [
    bat # v0.26.1
    coreutils # v9.12
    curl # v8.22.0
    delta # v0.20.1
    d2 # v0.9.0
    eza # v0.23.5
    findutils # v4.11.0
    gnugrep # v3.12
    gnused # v4.10
    gojq # v0.12.19
    # jq
    sops # v3.13.3
    tree # v2.3.2
    ripgrep # v15.2.0

    awscli2 # v2.36.31
    localPackages.apm
    localPackages.ax
    localPackages.claude-code
    localPackages.claude-desktop
    localPackages.codex
    localPackages.codex-desktop
    localPackages.difit
    docker_29 # v29.9.1
    fzf # v0.74.5
    ghq # v1.10.1
    git-secrets # v1.3.0
    go-task # v3.53.1
    tree-sitter # v0.26.11

    deno # v2.9.7
    fnm # v1.39.0
    go_1_27 # v1.27.3
    rustup # v1.29.2
    tenv # v4.15.1
    uv # v0.13.4
  ];
}
