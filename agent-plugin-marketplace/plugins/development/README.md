# Development

Codex CLI と Claude Code で共通利用する開発用 plugin です。

## Skills

- `git`: worktree と branch の作成、commit、rebase、push を扱う Git 実行手順
- `github-operation`: Draft PR 作成、CI 分析、review comment、Issue、Discussion の確認などの GitHub 操作を定型化する skill
- `development-flow`: 設計、チケット化、実装、レビューまでの上位フロー。設計時は `dig` skill、設計成果物作成後と実装後は `difit-review` skill を必須にする
- `japanese-tech-writing`: 日本語の技術文書・書籍原稿の文章規範。章、草稿、記事、解説文の執筆・推敲・リライトに使う
- `cognitive-rhythm-writing`: 説明文の緩急を、認知モードの切替と未回収の緊張として設計する文章規範

## MCP Server

- `aws`: `uvx mcp-proxy-for-aws==1.6.3 https://aws-mcp.us-east-1.api.aws/mcp --region ap-northeast-1`
- `terraform`: `docker run -i --rm hashicorp/terraform-mcp-server:1.1.0 --toolsets=registry`
- `github`: リモート GitHub MCP server `https://api.githubcopilot.com/mcp/`

GitHub MCP server を使う前に、`GITHUB_MCP_TOKEN` に最小権限の GitHub PAT を設定します。
GitHub MCP server は、`gh` で必要な読み取り専用の文脈を取得できない場合の fallback として使います。

## Required External Skills

`development-flow` は次の skill が同じ環境で使えることを前提にします。
plugin には同梱しません。

- `dig`: 設計、プラン、技術的意思決定の深掘り
- `difit-review`: 実装意図、トレードオフ、迷った点などを差分コメントに添えて人間レビューに出す

## Codex CLI

このリポジトリの marketplace を追加してから plugin を install します。

```sh
codex plugin marketplace add ./agent-plugin-marketplace
codex plugin add development@mami0tsu
```

Codex 用 MCP 設定は `.codex-plugin/plugin.json` に直接書きます。
Claude Code 用 MCP 設定は `.mcp.json` に置きます。
`bearer_token_env_var` は Codex 用の設定なので、Claude Code 用 `.mcp.json` には書きません。

Codex が plugin manifest からリモート GitHub MCP の認証設定を取り込めない場合は、GitHub MCP server を明示的に追加します。

```sh
codex mcp add github --url https://api.githubcopilot.com/mcp/ --bearer-token-env-var GITHUB_MCP_TOKEN
```

## Claude Code

このリポジトリの marketplace を追加してから plugin を install します。

```sh
claude plugin marketplace add ./agent-plugin-marketplace
claude plugin install development@mami0tsu
```

Claude Code が plugin MCP header 内の `GITHUB_MCP_TOKEN` を展開できない場合は、GitHub MCP server を明示的に追加します。

```sh
claude mcp add-json github '{"type":"http","url":"https://api.githubcopilot.com/mcp/","headers":{"Authorization":"Bearer '"$GITHUB_MCP_TOKEN"'"}}'
```
