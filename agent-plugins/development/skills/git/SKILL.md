---
name: git
description: >-
  開発フロー skill は、この skill を Git 実行手順として呼び出す。
  worktree と branch の作成、commit、push、fetch、local base の fast-forward 更新、rebase、wip branch の昇格を扱う。
  status、log、diff は単独の手順にせず、各手順の前提確認として使う。
---

# Git

開発フロー skill は、この skill を Git 実行手順として呼び出す。
ユーザーの開発目的を解釈する入口ではなく、指定された Git 作業を安全ルールに沿って実行する。

## 入力の責務

上位 skill は原則として使う runbook を明示する。
runbook 未指定でも、`commit`、`push`、`rebase`、`worktree`、`branch`、`fetch` のように Git 操作語が明確な場合だけ選択してよい。
曖昧な依頼では実行しない。

上位 skill が渡す情報:

- runbook 名
- ticket-id
- branch type
- short-description
- commit summary
- ユーザーが指定した file path

この skill が Git コマンドで取得する情報:

- repository root
- current branch
- dirty 状態
- remote base branch
- local base branch
- worktree 一覧
- branch の local/remote 存在
- merge-base と対象 commit

## 共通ルール

全ての状態変更 runbook は [references/rule-safety.md](references/rule-safety.md) を読む。
branch、worktree、commit message を作る runbook は [references/rule-naming.md](references/rule-naming.md) も読む。

実行前に、対象、現在状態、主要コマンド、停止条件を runbook に書かれた項目で表示する。
読み取り系 Git コマンドは独立 runbook にせず、各 runbook の前提確認として使う。

## Runbooks

- worktree と branch を作る: [references/start-worktree.md](references/start-worktree.md)
- 現在の base branch worktree で branch だけ作る: [references/start-branch.md](references/start-branch.md)
- staged 変更または指定 path を commit する: [references/commit-changes.md](references/commit-changes.md)
- 現在 branch を remote に push する: [references/push-branch.md](references/push-branch.md)
- remote base branch だけ更新する: [references/fetch-remote-base.md](references/fetch-remote-base.md)
- local base branch を fast-forward 更新する: [references/update-local-base.md](references/update-local-base.md)
- current branch を remote base branch に rebase する: [references/rebase-current-branch.md](references/rebase-current-branch.md)
- `wip/` branch を ticket-id 付き branch に昇格する: [references/promote-wip-branch.md](references/promote-wip-branch.md)

## GitHub 操作との境界

この skill は GitHub CLI/API を実行しない。
Draft PR の作成、PR close、remote `wip/` branch の削除は範囲外。
`wip/` branch は Draft PR の叩き台までは許容するが、通常 PR 化や merge は不可として扱う。
