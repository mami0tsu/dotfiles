{
  self,
  pkgs,
  username,
  ...
}:
{
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  system = {
    # nix-darwin 本体のバージョンに依存した後方互換性のための値を指定する
    # WARN: 原則変更しない
    #       https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-system.stateVersion
    stateVersion = 6;

    # ビルド時の設定ファイルのコミット位置を記録する
    configurationRevision = self.rev or self.dirtyRev or null;

    # システムレベルでのプライマリユーザーを指定する
    primaryUser = username;
  };

  # nix-darwin での Nix 管理を無効化する
  nix.enable = false;

  programs.zsh.enable = true;

  imports = [
    ./home-manager.nix
    ./homebrew.nix
    ./nixpkgs.nix
    ./system.nix
  ];
}
