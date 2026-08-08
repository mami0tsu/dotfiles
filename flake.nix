{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/6d12004108e0e4a5cfa4bd83b14477f040b15773"; # nixpkgs-unstable
    home-manager = {
      url = "github:nix-community/home-manager/3139deb8cafbe73b39b24451255b2fdd3426077e"; # master
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/57a3171f94705599a2499248ca5758d5eb47c0e0"; # master
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew/842eeb863ecca0eeb463f7a814cdc51e1d925776"; # main
      inputs.brew-src.follows = "brew-src";
    };
    brew-src = {
      url = "github:Homebrew/brew/860497fef02b98811b838f522beb1578b5c5c14c"; # master
      flake = false;
    };
  };

  outputs =
    {
      home-manager,
      nix-darwin,
      nix-homebrew,
      nixpkgs,
      self,
      ...
    }@inputs:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };

      localPackages = import ./nix/packages { inherit (pkgs) callPackage; };

      getDarwinConfig =
        username: useremail:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              username
              useremail
              ;
            nix-homebrew = inputs.nix-homebrew;
            self = inputs.self;
          };
          modules = [
            ./nix/nix-darwin/configuration.nix
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
          ];
        };
    in
    {
      darwinConfigurations.ci = getDarwinConfig "ci" "mami0tsu.jp+ci@gmail.com";
      darwinConfigurations.mami0tsu = getDarwinConfig "mami0tsu" "mami0tsu.jp@gmail.com";
      packages.${system} = localPackages;
      checks.${system} =
        pkgs.lib.mapAttrs (
          name: package:
          pkgs.runCommand "${name}-smoke-test"
            {
              nativeBuildInputs = [ package ];
            }
            ''
              ${pkgs.lib.getExe package} --version
              touch "$out"
            ''
        ) (pkgs.lib.filterAttrs (_: package: package.meta ? mainProgram) localPackages)
        // {
          git-open-src-syntax = pkgs.runCommand "git-open-src-syntax" { nativeBuildInputs = [ pkgs.zsh ]; } ''
            zsh -n ${localPackages.git-open-src}/git-open
            touch "$out"
          '';
          zsh-defer-src-syntax =
            pkgs.runCommand "zsh-defer-src-syntax" { nativeBuildInputs = [ pkgs.zsh ]; }
              ''
                zsh -n ${localPackages.zsh-defer-src}/zsh-defer.plugin.zsh
                touch "$out"
              '';
        };
    };
}
