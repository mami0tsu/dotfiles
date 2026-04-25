{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/9b8e6819224551756919099c1fce6e347f5a3803"; # nixpkgs-25.11-darwin
    home-manager = {
      url = "github:nix-community/home-manager/49ca96b2714c5931e17401eff87f3edd42d2b0f2"; # release-25.11
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/ebec37af18215214173c98cf6356d0aca24a2585"; # nix-darwin-25.11
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew/99c7ead19cd22ce16cc550a9acf7d70de0142679"; # brew-5.1.1
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.brew-src.follows = "brew-src";
    };
    brew-src = {
      url = "github:Homebrew/brew/894a3d23ac0c8aaf561b9874b528b9cb2e839201"; # 5.1.1
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-homebrew,
      ...
    }@inputs:
    let
      system = "aarch64-darwin";

      # 共通の darwinSystem 構成を生成する関数を定義する
      getDarwinConfig =
        username: system:
        nix-darwin.lib.darwinSystem {
          system = system;
          specialArgs = {
            inputs = inputs;
            nix-homebrew = inputs.nix-homebrew;
            self = inputs.self;
            username = username;
          };
          modules = [
            ./nix/nix-darwin/configuration.nix
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
          ];
        };
    in
    {
      darwinConfigurations.mami0tsu = getDarwinConfig "mami0tsu" system;

      # CI 環境の設定を定義する
      darwinConfigurations.ci = getDarwinConfig "ci-user" system;
    };
}
