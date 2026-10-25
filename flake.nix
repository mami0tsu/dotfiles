{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/901c54c08bdc20e00c2b3c73716b97497b1b3c74"; # nixpkgs-unstable
    home-manager = {
      url = "github:nix-community/home-manager/2cd3234928f60bbff695a7ee56115ef7799c47cd"; # master
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/bb0b90dbd54e207100de72b5dcbe3188c98a4b69"; # master
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew/c11cccfdd36dd69b5323d70d354b2853379c2426"; # main
      inputs.brew-src.follows = "brew-src";
    };
    brew-src = {
      url = "github:Homebrew/brew/7.0.10";
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
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = package:
          builtins.elem (nixpkgs.lib.getName package) [
            "claude-code"
            "claude-desktop"
            "codex-desktop"
          ];
      };

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      localPackages = import ./nix/packages { inherit (pkgs) callPackage; };

      getLintTools =
        pkgs:
        let
          lintPackages = import ./nix/packages { inherit (pkgs) callPackage; };
        in
        [
          pkgs.actionlint
          lintPackages.ghalint
          pkgs.shellcheck
          lintPackages.textlint
          pkgs.yamllint
          pkgs.zizmor
        ];

      getTestTools = pkgs: [
        pkgs.go-task
        (pkgs.python315.withPackages (pythonPackages: [
          pythonPackages.jsonschema
          pythonPackages.pyyaml
        ]))
        pkgs.renovate
      ];

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
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          lint = pkgs.mkShellNoCC {
            packages = getLintTools pkgs;
          };
          test = pkgs.mkShellNoCC {
            packages = getTestTools pkgs;
          };
        }
      );
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
