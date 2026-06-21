---
name: github-operation
description: Draft PR 作成、PR の CI 実行結果分析、レビューコメント確認、Issues/Discussions の参照など、GitHub 上の定型操作と分析を行うときに使う。基本は GitHub CLI を優先し、GitHub CLI が認証済みでも取得失敗・機能不足・API 差分で進められない場合だけ GitHub MCP に fallback する。
allowed-tools: >-
  Bash(gh api:*)
  Bash(gh auth status:*)
  Bash(gh issue view:*)
  Bash(gh pr checks:*)
  Bash(gh pr create:*)
  Bash(gh pr view:*)
  Bash(gh repo view:*)
  Bash(gh run view:*)
  Bash(git branch:*)
  Bash(git remote:*)
  Bash(git rev-parse:*)
  Bash(git status:*)
  Read
---

# GitHub Operation

GitHub 上の操作と分析を日本語の運用ルールに沿って定型化する。ローカル Git の branch 作成、commit、push は扱わない。

GitHub MCP fallback は `development` plugin が提供する GitHub MCP server を使う。Codex 固有の GitHub app connector は fallback 前提にしない。

## 使う場面

次の依頼ではこの skill を使う:

- Draft PR を作成する
- PR の CI 実行結果を分析する
- PR のレビューコメントや未解決 thread を確認する
- Issue を実装の参考情報として読む
- Discussion を実装の参考情報として読む

## 最初に読むファイル

操作前に、必ず必要な共通ルールだけを読む:

- GitHub 対象の解決: [common/context.md](common/context.md)
- 安全ルール: [common/safety.md](common/safety.md)
- GitHub CLI と MCP の使い分け: [common/mcp-cli-policy.md](common/mcp-cli-policy.md)
- PR template と fallback body: [common/pr-template.md](common/pr-template.md)
- 実行計画の出し方: [common/execution-plan.md](common/execution-plan.md)

## 操作の選び方

依頼内容に最も近い operation を読む:

- Draft PR を作成する: [operations/create-draft-pr.md](operations/create-draft-pr.md)
- PR の CI を分析する: [operations/analyze-ci.md](operations/analyze-ci.md)
- レビューコメントを確認する: [operations/check-review-comments.md](operations/check-review-comments.md)
- Issue を確認する: [operations/check-issue.md](operations/check-issue.md)
- Discussion を確認する: [operations/check-discussion.md](operations/check-discussion.md)

## ローカル Git 操作との境界

この skill は GitHub 操作と分析に集中する。Draft PR 作成時に branch が remote に push されていない場合は、push コマンド例を示して中止する。

```sh
git push -u origin <branch-name>
```

この skill 自体では branch 作成、commit、push、rebase は実行しない。
