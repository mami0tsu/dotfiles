{
  inputs,
  nix-homebrew,
  username,
  ...
}:
let
  flakeLock = builtins.fromJSON (builtins.readFile "${inputs.self}/flake.lock");
  brewVersion = flakeLock.nodes.brew-src.original.ref;
in
{
  nix-homebrew = {
    enable = true;
    user = username;
    package = inputs.brew-src // {
      name = "brew-${brewVersion}";
      version = brewVersion;
    };

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
