# Development

Codex CLI と Claude Code で共通利用する開発用 plugin です。

## Skills

| スキル | 用途 |
| --- | --- |
| `assess-pr-review-comments` | PR feedback の妥当性と対応候補を修正前に整理するフロー |
| `git-usage` | worktree、branch、commit、rebase、push を扱う Git リファレンス |
| `gh-usage` | Draft PR、CI、review comment、Issue、Discussion を扱う GitHub CLI リファレンス |
| `jira-usage` | Atlassian Rovo MCP で Jira ticket を操作する provider adapter |
| `linear-usage` | Linear MCP で ticket と依存関係を操作する provider adapter |
| `pr-review-response-flow` | PR feedback の評価、修正、検証、pending reply を統括するフロー |
| `ticket-usage` | provider 非依存の契約で ticket と依存関係を操作する共通 adapter |
| `pre-push-review` | commit 済み差分の敵対的検証と difit 人間レビューを反復するフロー |
| `reply-to-pr-review-comments` | 承認済み返信案を記録済み pending review に追加するフロー |
| `retrospective` | AI の振る舞いと権限設定の改善候補を YAML で記録するフロー |
| `workflow-state` | 複数 worktree と人間待ちをまたぐ workflow 状態を管理する共通基盤 |
| `dev-flow` | チケットに沿った実装、検証、レビュー、Draft PR、振り返りの上位フロー |

## MCP サーバー

| MCP サーバー | 用途 |
| --- | --- |
| `atlassian` | Jira の参照と更新 |
| `aws` | AWS の操作 |
| `linear` | Linear の参照 |
| `terraform` | Terraform Registry の参照 |
