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

  # macOS のシステムレベルでのプライマリユーザーを指定する
  system.primaryUser = username;

  # キーボードのリマップ設定を定義する
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true; # Caps Lock を Control に変更
  };

  # macOS のシステム設定を変更する
  system.defaults = {
    # Finder の設定を定義する
    finder = {
      AppleShowAllFiles = true; # 隠しファイルを表示する
      ShowPathbar = true; # パスバーを表示する
      ShowStatusBar = true; # ステータスバーを表示する
      _FXShowPosixPathInTitle = true; # タイトルバーにフルパスを表示する
    };

    # Dock の設定を定義する
    dock = {
      autohide = true; # Dock を自動的に隠す
      show-recents = false; # 最近使ったアプリを表示しない
      mru-spaces = false; # 操作スペースを自動で並べ替えない
    };

    # システム全体の挙動を定義する
    NSGlobalDomain = {
      AppleShowAllExtensions = true; # ファイルの拡張子を常に表示する
      AppleInterfaceStyle = "Dark"; # ダークモードを有効にする
      InitialKeyRepeat = 15; # キーリピート開始までの待機時間を最短に設定
      KeyRepeat = 2; # キーリピートの速度を最速に設定
    };
  };

  # Nixpkgs の動作設定を行い unfree パッケージの利用を許可する
  nixpkgs.config.allowUnfree = true;
}
