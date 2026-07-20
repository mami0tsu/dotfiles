# Agent Plugin Marketplace

Codex CLI と Claude Code で共通利用する agent plugin marketplace です。

Marketplace name は `mami0tsu` です。

## 構造

- Codex marketplace: `.agents/plugins/marketplace.json`
- Claude Code marketplace: `.claude-plugin/marketplace.json`
- Plugin packages: `plugins/<plugin>/`

## Plugins

- `development`: Codex CLI と Claude Code で共通利用する開発用 plugin
- `documentation`: 日本語の技術文書と D2 diagram を作成する plugin

## Codex CLI

```sh
codex plugin marketplace add ./agent-plugin-marketplace
codex plugin add development@mami0tsu
codex plugin add documentation@mami0tsu
```

## Claude Code

```sh
claude plugin marketplace add ./agent-plugin-marketplace
claude plugin install development@mami0tsu
claude plugin install documentation@mami0tsu
```

## 旧 marketplace からの移行

旧 marketplace name `dotfiles` の登録を削除するときは、次の task を使います。

```sh
task agent-plugins:migrate
```
