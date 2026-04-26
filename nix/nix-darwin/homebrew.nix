{
  nix-homebrew,
  username,
  ...
}:
{
  nix-homebrew = {
    enable = true;
    user = username;

    autoMigrate = true;
    enableRosetta = false;
  };

  homebrew = {
    enable = true;
    user = username;

    global.autoUpdate = false;
    onActivation = {
      autoUpdate = false;
      upgrade = true;
      # cleanup = "uninstall"; # Homebrew からの移行完了後に設定
    };

    brews = [ ];
    casks = [
      "discord"
      "ghostty"
      "google-chrome"
      "orbstack"
      "slack"
      "visual-studio-code"
    ];
  };
}
