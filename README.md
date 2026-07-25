# dotfiles

Apple Silicon Mac (`aarch64-darwin`) の開発環境を管理する dotfiles です。

| flake target | 用途 |
| --- | --- |
| `mami0tsu` | 通常利用 |
| `ci` | CI |

## 管理範囲

| 対象 | 内容 |
| --- | --- |
| macOS | nix-darwin と Home Manager で適用する基本設定 |
| 開発ツール | shell、editor、terminal などの設定 |
| Agent | Agent Plugins と Agent Skills |

## 初回セットアップ

Nix を flakes 有効の状態でインストールします。

```sh
curl -sSfL -o /tmp/nix-installer https://artifacts.nixos.org/nix-installer/nix-installer-aarch64-darwin
chmod +x /tmp/nix-installer
/tmp/nix-installer install --enable-flakes
```

インストール後は、新しいシェルを開くか macOS を再起動します。

初回は `darwin-rebuild` や `task` がまだ入っていないため、Nix から直接適用します。

```sh
export TARGET=mami0tsu
sudo nix --extra-experimental-features "nix-command flakes" run \
  github:nix-darwin/nix-darwin#darwin-rebuild -- \
  switch --flake ".#$TARGET"
```

初回適用後は、`task deploy` で Agent Plugins と Agent Skills まで揃えます。

```sh
task deploy
```

## 環境の更新

設定変更は次のコマンドで反映します。

```sh
task deploy
```

target を明示する場合は、`TARGET` を指定して実行します。

```sh
TARGET=mami0tsu task deploy
```

古い Nix generation と生成済みの agent 関連ファイルは、次のコマンドで削除します。

```sh
task clean
```

## 参考

- nix-installer: https://github.com/NixOS/nix-installer
- nix-darwin: https://github.com/nix-darwin/nix-darwin
- Home Manager: https://github.com/nix-community/home-manager
- APM: https://github.com/microsoft/apm
