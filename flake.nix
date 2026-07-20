{
  description = "";

  inputs = {
    nixpkgs.url =
      "github:nixos/nixpkgs/141f212d3652c61515ba4e9478c8093fca278bac"; # nixpkgs-unstable
    home-manager = {
      url =
        "github:nix-community/home-manager/3139deb8cafbe73b39b24451255b2fdd3426077e"; # master
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url =
        "github:nix-darwin/nix-darwin/57a3171f94705599a2499248ca5758d5eb47c0e0"; # master
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

      localPackages = {
        apm = pkgs.callPackage ./nix/packages/apm.nix { };
        ax = pkgs.callPackage ./nix/packages/ax.nix { };
        codex = pkgs.callPackage ./nix/packages/codex.nix { };
        difit = pkgs.callPackage ./nix/packages/difit.nix { };
        git-open-src = pkgs.callPackage ./nix/packages/git-open-src.nix { };
        git-wt = pkgs.callPackage ./nix/packages/git-wt.nix { };
        roots = pkgs.callPackage ./nix/packages/roots.nix { };
        zsh-defer-src = pkgs.callPackage ./nix/packages/zsh-defer-src.nix { };
      };

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
    };
}
