{ pkgs, username, ... }:

{
  # macOS システム全体のユーザー設定を定義する
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # nix-darwin の状態バージョンを指定しインストール時の値を維持する
  system.stateVersion = 4;

  # Nix の動作設定を行い Flakes と新しい CLI コマンドを有効にする
  nix.settings.experimental-features = "nix-command flakes";

  # zsh をシステムレベルで有効化し /etc/zshrc を自動生成する
  programs.zsh.enable = true;

  # macOS のシステム設定を変更しファイルの拡張子を常に表示する
  system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;

  # Nixpkgs の動作設定を行い unfree パッケージの利用を許可する
  nixpkgs.config.allowUnfree = true;
}
