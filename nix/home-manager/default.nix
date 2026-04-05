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
    ponysay
  ];

  programs.home-manager.enable = true;
}
