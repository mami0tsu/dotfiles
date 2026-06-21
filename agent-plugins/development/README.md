# Development

Codex CLI と Claude Code で共通利用する開発用 plugin です。

## MCP Server

- `aws`: `uvx mcp-proxy-for-aws@1.6.0 https://aws-mcp.us-east-1.api.aws/mcp --metadata AWS_REGION=ap-northeast-1`
- `terraform`: `docker run -i --rm hashicorp/terraform-mcp-server:1.0.0`
- `github`: リモート GitHub MCP server `https://api.githubcopilot.com/mcp/`

GitHub MCP server を使う前に、`GITHUB_MCP_TOKEN` に最小権限の GitHub PAT を設定します。
GitHub MCP server は、`gh` で必要な読み取り専用の文脈を取得できない場合の fallback として使います。

## Codex CLI

このリポジトリの marketplace を追加してから plugin を install します。

```sh
codex plugin marketplace add ./agent-plugins
codex plugin add development@dotfiles
```

Codex が plugin manifest からリモート GitHub MCP の認証設定を取り込めない場合は、GitHub MCP server を明示的に追加します。

```sh
codex mcp add github --url https://api.githubcopilot.com/mcp/ --bearer-token-env-var GITHUB_MCP_TOKEN
```

## Claude Code

このリポジトリの marketplace を追加してから plugin を install します。

```sh
claude plugin marketplace add ./agent-plugins
claude plugin install development@dotfiles
```

Claude Code が plugin MCP header 内の `GITHUB_MCP_TOKEN` を展開できない場合は、GitHub MCP server を明示的に追加します。

```sh
claude mcp add-json github '{"type":"http","url":"https://api.githubcopilot.com/mcp/","headers":{"Authorization":"Bearer '"$GITHUB_MCP_TOKEN"'"}}'
```
