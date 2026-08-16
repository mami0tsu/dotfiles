# Development

Codex CLI と Claude Code で共通利用する開発用 plugin です。

## Skills

| スキル | 用途 |
| --- | --- |
| `git-usage` | worktree、branch、commit、rebase、push を扱う Git リファレンス |
| `gh-usage` | Draft PR、CI、review comment、Issue、Discussion を扱う GitHub CLI リファレンス |
| `jira-usage` | Atlassian Rovo MCP で Jira ticket を操作する provider adapter |
| `linear-usage` | Linear MCP で ticket と依存関係を操作する provider adapter |
| `review` | コードとテキスト文書の検証、関心別 commit、difit 人間レビューを反復するフロー |
| `retrospective` | AI の振る舞いと権限設定の改善候補を YAML で記録するフロー |
| `ticket-usage` | provider 非依存の契約で ticket と依存関係を操作する共通 adapter |
| `dev-flow` | チケットに沿った実装、検証、レビュー、Draft PR、振り返りの上位フロー |

## MCP サーバー

| MCP サーバー | 用途 |
| --- | --- |
| `aws` | AWS の操作 |
| `atlassian` | Jira の参照と更新 |
| `terraform` | Terraform Registry の参照 |
| `linear` | Linear の参照 |
