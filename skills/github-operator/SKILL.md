---
name: github-operator
description: Draft PR 作成、PR の CI 実行結果分析、レビューコメント確認、Issues/Discussions の参照など、GitHub 上の定型操作と分析を行うときに使う。基本は GitHub MCP を優先し、Actions logs や review thread など MCP が弱い領域だけ GitHub CLI を使う。
allowed-tools: >-
  Bash(gh api:*)
  Bash(gh auth status:*)
  Bash(gh pr checks:*)
  Bash(gh pr create:*)
  Bash(gh pr view:*)
  Bash(gh run view:*)
  Bash(git branch:*)
  Bash(git remote:*)
  Bash(git rev-parse:*)
  Bash(git status:*)
  Read
  mcp__codex_apps__github._create_pull_request
  mcp__codex_apps__github._fetch_file
  mcp__codex_apps__github._fetch_issue
  mcp__codex_apps__github._fetch_issue_comments
  mcp__codex_apps__github._fetch_pr
  mcp__codex_apps__github._fetch_pr_comments
  mcp__codex_apps__github._get_pr_info
  mcp__codex_apps__github._get_repo
  mcp__codex_apps__github._list_pull_request_review_threads
  mcp__codex_apps__github._search
  mcp__codex_apps__github._search_issues
---

# GitHub Operator

GitHub 上の操作と分析を日本語の運用ルールに沿って定型化する。ローカル Git の branch 作成、commit、push は扱わない。

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
- MCP と GitHub CLI の使い分け: [common/mcp-cli-policy.md](common/mcp-cli-policy.md)
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
