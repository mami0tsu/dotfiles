# Agent Plugin Marketplace

Codex CLI と Claude Code で共通利用する agent plugin marketplace です。

Marketplace name は `mami0tsu` です。

## Plugins

| プラグイン | 用途 |
| --- | --- |
| `development` | 開発フロー、Git/GitHub 操作、共通 MCP server を扱うプラグイン |
| `documentation` | 日本語の技術文書と D2 diagram を作成するプラグイン |

## セットアップと削除

marketplace と plugin は次の task で登録します。

```sh
task agent-plugins:deploy
```

登録を削除するときは次の task を使います。

```sh
task agent-plugins:clean
```
