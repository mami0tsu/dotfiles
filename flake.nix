{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      ...
    }@inputs:
    let
      # local.nix が存在する場合は読み込み、存在しない場合は空のセットを返す
      localConfig = if builtins.pathExists ./local.nix then import ./local.nix else { };

      # ユーザー名が指定されていない場合にエラーを表示する
      username =
        localConfig.username
          or (throw ''
            Error: 'local.nix' is missing or 'username' is not defined.
            Please create 'local.nix' with the following content:
            {
              username = "your-username";
            }
          '');

      system = "aarch64-darwin";

      # 共通の darwinSystem 構成を生成する関数を定義する
      getDarwinConfig =
        username: system:
        nix-darwin.lib.darwinSystem {
          system = system;
          specialArgs = {
            inputs = inputs;
            self = inputs.self;
            username = username;
          };
          modules = [
            ./nix/nix-darwin/configuration.nix
            home-manager.darwinModules.home-manager
          ];
        };
    in
    {
      darwinConfigurations.mami0tsu = getDarwinConfig "mami0tsu" system;

      # CI 環境の設定を定義する
      darwinConfigurations.ci = getDarwinConfig "ci-user" system;
    };
}
