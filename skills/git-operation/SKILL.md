---
name: git-operator
description: branch/worktree 作成、commit、rebase、push、wip 昇格など、定型化された Git 操作を行うときに使う。単純な status/log/diff の確認だけでは使わない。
allowed-tools: >-
  Bash(git add:*)
  Bash(git branch:*)
  Bash(git commit:*)
  Bash(git config:*)
  Bash(git fetch:*)
  Bash(git log:*)
  Bash(git merge-base:*)
  Bash(git pull:*)
  Bash(git push:*)
  Bash(git rebase:*)
  Bash(git rev-parse:*)
  Bash(git show-ref:*)
  Bash(git status:*)
  Bash(git switch:*)
  Bash(git symbolic-ref:*)
  Bash(git worktree:*)
  Bash(git wt:*)
  Read
---

# Git Operator

Git 操作を日本語の運用ルールに沿って定型化する。単純な `git status`、`git log`、`git diff` の確認では使わない。

## 使う場面

次の依頼ではこの skill を使う:

- 新しい作業を始める
- branch または worktree を作る
- branch を切り替える
- commit を作る
- branch を push する
- 現在 branch を base branch に rebase する
- `wip/` branch を ticket-id 付き branch に昇格する

## 最初に読むファイル

操作前に、必ず必要な共通ルールだけを読む:

- Git 状態の取得: [common/context.md](common/context.md)
- 安全ルール: [common/safety.md](common/safety.md)
- branch/worktree/commit の命名: [common/naming.md](common/naming.md)
- 実行計画の出し方: [common/execution-plan.md](common/execution-plan.md)

## 操作の選び方

ユーザーが「作業を始める」とだけ言った場合は、デフォルトで [operations/create-worktree.md](operations/create-worktree.md) を使う。ユーザーが「このディレクトリで」「branch だけ」「worktree は不要」などを明示した場合だけ [operations/create-branch.md](operations/create-branch.md) を使う。

その他の操作は、依頼内容に最も近い operation を読む:

- branch だけ作る: [operations/create-branch.md](operations/create-branch.md)
- worktree を作る: [operations/create-worktree.md](operations/create-worktree.md)
- branch を切り替える: [operations/switch-branch.md](operations/switch-branch.md)
- commit する: [operations/make-commit.md](operations/make-commit.md)
- push する: [operations/push-branch.md](operations/push-branch.md)
- remote base だけ更新する: [operations/fetch-remote-base.md](operations/fetch-remote-base.md)
- local base branch を更新する: [operations/update-local-base-branch.md](operations/update-local-base-branch.md)
- current branch を rebase する: [operations/rebase-current-branch.md](operations/rebase-current-branch.md)
- `wip/` を ticket-id 付き branch に昇格する: [operations/promote-wip-branch.md](operations/promote-wip-branch.md)

## GitHub 操作との境界

この skill は GitHub CLI/API を実行しない。Draft PR の作成、PR close、remote `wip/` branch の削除は範囲外。`wip/` branch は Draft PR の叩き台までは許容するが、通常 PR 化や merge は不可として扱う。
