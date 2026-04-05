{ config, pkgs, username, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = username;

  # Home Manager の互換性を保つための状態バージョンを指定する
  home.stateVersion = "25.11";

  # The star of the show
  home.packages = with pkgs; [
    ponysay
  ];

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
