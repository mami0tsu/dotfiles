{
  description = "";

  inputs = {
    nixpkgs.url =
      "github:nixos/nixpkgs/ffa10e26ae11d676b2db836259889f1f571cb14f"; # nixpkgs-unstable
    home-manager = {
      url =
        "github:nix-community/home-manager/b2b7db486e06e098711dc291bb25db82850e1d16"; # master
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url =
        "github:nix-darwin/nix-darwin/56c666e108467d87d13508936aade6d567f2a501"; # master
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew/99c7ead19cd22ce16cc550a9acf7d70de0142679"; # brew-5.1.1
      inputs.brew-src.follows = "brew-src";
    };
    brew-src = {
      url = "github:Homebrew/brew/894a3d23ac0c8aaf561b9874b528b9cb2e839201"; # 5.1.1
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
