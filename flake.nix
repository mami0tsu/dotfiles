{
  description = "FlakeHub と nix-darwin を活用した macOS 環境設定";

  inputs = {
    # FlakeHub から安定版の Nixpkgs を取得しサプライチェーンの安全性を確保する
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2511.*";

    # Home Manager を GitHub の安定版リリースブランチから取得する
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin を GitHub の安定版ブランチから取得する
    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      darwin,
      ...
    }@inputs:
    let
      # local.nix が存在する場合は読み込み、存在しない場合は空のセットを返す
      localConfig = if builtins.pathExists ./local.nix then import ./local.nix else { };

      # ユーザー名が指定されていない場合にエラーを表示する
      # CI 環境以外（ローカル環境）では local.nix による明示的な指定を求める
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
      # サポート対象とするシステムを定義する
      supportedSystems = [ "aarch64-darwin" ];
      # 各システムごとにパッケージや設定を生成するヘルパー関数として定義する
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          }
        );

      # 共通の darwinSystem 構成を生成する関数を定義する
      mkDarwinConfig =
        user: sys:
        darwin.lib.darwinSystem {
          system = sys;
          specialArgs = {
            inherit inputs;
            username = user;
          };
          modules = [
            ./darwin-configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${user} = import ./home.nix;
              home-manager.extraSpecialArgs = {
                inherit inputs;
                username = user;
              };
            }
          ];
        };
    in
    {
      # macOS システムの設定を定義する
      # local.nix での定義を強制し、未定義の場合はビルドエラーにする
      darwinConfigurations.local = mkDarwinConfig username system;

      # GitHub Actions などの CI 環境向けの構成を定義する
      # CI 環境では特定のアカウント 'ci-user' でビルドを成功させる
      darwinConfigurations.ci = mkDarwinConfig "ci-user" system;

      # Nix ファイルに対して標準的なフォーマットを適用する
      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt-rfc-style);

      # nix develop コマンドで使用する開発用シェル環境を定義する
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [ self.formatter.${system} ];
          };
        }
      );
    };
}
