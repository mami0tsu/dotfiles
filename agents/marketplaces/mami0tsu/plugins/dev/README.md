# Development

Codex CLI と Claude Code で共通利用する開発用 plugin です。

## Skills

| スキル | 用途 |
| --- | --- |
| `git-usage` | worktree、branch、commit、rebase、push を扱う Git リファレンス |
| `gh-usage` | Draft PR、CI、review comment、Issue、Discussion を扱う GitHub CLI リファレンス |
| `pre-push-review` | commit 済み差分の敵対的検証と difit 人間レビューを反復するフロー |
| `retrospective` | AI の振る舞いと権限設定の改善候補を YAML で記録するフロー |
| `workflow-state` | 複数 worktree と人間待ちをまたぐ workflow 状態を管理する共通基盤 |
| `dev-flow` | チケットに沿った実装、検証、レビュー、Draft PR、振り返りの上位フロー |

## MCP サーバー

| MCP サーバー | 用途 |
| --- | --- |
| `aws` | AWS の操作 |
| `terraform` | Terraform Registry の参照 |
| `linear` | Linear の参照 |
