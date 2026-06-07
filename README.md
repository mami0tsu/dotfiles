# dotfiles

Apple Silicon Mac (`aarch64-darwin`) の環境を nix-darwin と Home Manager で管理する dotfiles です。

## flake target

現在の flake target は次の通りです。

- `mami0tsu`
- `ci`

別の target を使う場合は `flake.nix` に追加します。

```nix
darwinConfigurations.example = getDarwinConfig "example" "example@example.com";
```

初期設定や環境の更新では、使う target を `TARGET` に指定します。

```sh
export TARGET=mami0tsu
```

## 初期設定

### 1. Nix のインストール

nix-installer を使って Nix をインストールします。

```sh
curl -sSfL -o /tmp/nix-installer https://artifacts.nixos.org/nix-installer/nix-installer-aarch64-darwin
chmod +x /tmp/nix-installer
/tmp/nix-installer install --enable-flakes
```

インストール後、案内に従って新しいシェルを開くか macOS を再起動します。

### 2. nix-darwin の初回実行

初回は `darwin-rebuild` や `task` がまだ入っていないため、Nix から直接実行します。

```sh
export TARGET=mami0tsu
sudo nix --extra-experimental-features "nix-command flakes" run \
  github:nix-darwin/nix-darwin#darwin-rebuild -- \
  switch --flake ".#$TARGET"
```

この時点で Home Manager の設定、Nix パッケージ、Homebrew cask、各種 dotfiles のリンクが適用されます。

## 環境の更新

設定変更は次のコマンドで反映します。

```sh
task deploy
```

target を明示する場合は `TARGET` に指定します。

```sh
TARGET=mami0tsu task deploy
```

古い Nix generation は次のコマンドで削除します。

```sh
task clean
```

## 管理内容

Nix 側で主に次の項目を管理しています。

- macOS defaults
- Homebrew casks
- Home Manager
- Git
- Zsh
- Starship
- Neovim / nixvim
- CLI packages
- dotfiles の XDG config リンク

設定ファイル本体は、各ツールの標準形式のまま管理しています。

- `starship/starship.toml`
- `ghostty/config`
- `zellij/config.kdl`
- `espanso/`
- `nvim/`

## 参考

- nix-installer: https://github.com/NixOS/nix-installer
- nix-darwin: https://github.com/nix-darwin/nix-darwin
- Home Manager: https://github.com/nix-community/home-manager
