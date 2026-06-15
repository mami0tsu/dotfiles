{
  useremail,
  username,
  ...
}:
{
  home.username = username;

  # Home Manager の互換性を保つための状態バージョンを指定する
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  imports = [
    ./agent-mcp.nix
    ./agent-skills.nix
    ./dotfiles.nix
    ./git.nix
    ./nixvim.nix
    ./packages.nix
    ./packages-go.nix
    ./starship.nix
    ./zsh.nix
  ];
}
