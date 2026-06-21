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

### 3. APM 管理 skill のインストール

外部由来の skill は APM で管理します。初回適用後に、lockfile に固定された skill を materialize して、Codex / Claude の global skill directory に symlink します。

```sh
task agent-skills:install
```

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

## Agent Skills

Agent Skills は、自作 skill と外部由来 skill で管理方法を分けています。

- 自作 skill: `skills/<name>/SKILL.md` として管理し、Home Manager が `.codex/skills` と `.claude/skills` に symlink します。
- 外部由来 skill: `apm.yml` と `apm.lock.yaml` で管理します。生成物は `.agents/skills` に置かれ、`task agent-skills:install` が `.codex/skills` と `.claude/skills` に symlink します。

外部由来 skill は commit pin を厳守します。依存を追加・削除した場合や commit pin を変更した場合だけ、次のコマンドで APM 出力を作り直します。

```sh
task agent-skills:refresh
```

`.agents/` と `apm_modules/` は生成物なので Git 管理しません。

## Agent Plugin と MCP Server

Agent MCP server のランタイム設定は、Codex CLI と Claude Code のネイティブな
plugin install/update に寄せます。Home Manager は MCP 設定ファイルを生成しません。

共通 plugin は `agent-plugins/development` で管理します。

- Codex marketplace: `agent-plugins/.agents/plugins/marketplace.json`
- Claude Code marketplace: `agent-plugins/.claude-plugin/marketplace.json`
- Plugin package: `agent-plugins/development`

含めている skill は次の通りです。

- `git-operation`: branch/worktree 作成、commit、rebase、push などの Git 操作

初期 MCP server は次の通りです。

- AWS MCP: `uvx mcp-proxy-for-aws@1.6.0 https://aws-mcp.us-east-1.api.aws/mcp --metadata AWS_REGION=ap-northeast-1`
- Terraform MCP: `docker run -i --rm hashicorp/terraform-mcp-server:1.0.0`
- GitHub MCP: `https://api.githubcopilot.com/mcp/`

GitHub MCP は `gh` で取得できない読み取り専用の文脈を補う fallback として使います。
`GITHUB_MCP_TOKEN` に最小権限の PAT を設定します。秘密値は dotfiles では管理しません。

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
- Agent Skills の symlink
- Agent plugin marketplace
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
- APM: https://github.com/microsoft/apm
