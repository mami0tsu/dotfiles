# Development

Codex CLI と Claude Code で共通利用する開発用 plugin です。

## Skills

| スキル | 用途 |
| --- | --- |
| `git-usage` | worktree、branch、commit、rebase、push を扱う Git リファレンス |
| `gh-usage` | Draft PR、CI、review comment、Issue、Discussion を扱う GitHub CLI リファレンス |
| `review` | コードとテキスト文書の検証、関心別 commit、difit 人間レビューを反復するフロー |
| `retrospective` | AI の振る舞いと権限設定の改善候補を YAML で記録するフロー |
| `dev-flow` | チケットに沿った実装、検証、レビュー、Draft PR、振り返りの上位フロー |

## MCP サーバー

| MCP サーバー | 用途 |
| --- | --- |
| `aws` | AWS の操作 |
| `terraform` | Terraform Registry の参照 |
| `github` | GitHub の参照 |
| `linear` | Linear の参照 |

## GitHub 認証

GitHub MCP はリモートサーバーを使う。

Codex は `bearer_token_env_var`、Claude Code は `Authorization` header で、同じ `GITHUB_MCP_TOKEN` を参照する。

対話シェルの `codex` と `claude` は、macOS Keychain に保存した `gh` の認証から token を取得してから起動する。

取得した token は GitHub MCP 用の `GITHUB_MCP_TOKEN` と、エージェント内の `gh` 用の `GH_TOKEN` として、そのプロセスだけに渡す。

保存済み認証は `GH_TOKEN= GITHUB_TOKEN= gh auth status --hostname github.com` で確認する。

認証の更新は `GH_TOKEN= GITHUB_TOKEN= gh auth login --hostname github.com --web` で行う。

token は起動したプロセスにだけ渡し、シェル全体へは export しない。
