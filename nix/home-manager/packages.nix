{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    bat # v0.26.1
    coreutils # v9.11
    curl # v8.20.0
    delta # v0.19.2
    eza # v0.23.4
    findutils # v4.10.0
    gnugrep # v3.12
    gnused # v4.9
    gojq # v0.12.19
    # jq
    tree # v2.3.2
    ripgrep # v15.1.0

    awscli2 # v2.34.24
    (pkgs.callPackage ../packages/apm.nix { }) # v0.20.0
    codex # 0.135.0
    docker_29 # v29.5.2
    fzf # v0.73.1
    gh # v2.93.0
    ghq # v1.9.4
    git-secrets # v1.3.0
    go-task # v3.48.0
    starship # v1.25.1
    tree-sitter # v0.26.8
    zellij # v0.44.3

    deno # v2.8.0
    fnm # v1.39.0
    go # v1.26.3
    rustup # v1.29.0
    tenv # v4.12.2
    uv # v0.11.17
  ];
}
