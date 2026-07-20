---
name: git-usage
description: Git を安全かつ効率的に使うためのリファレンス。status、diff、branch、worktree、commit、fetch、pull、rebase、push を扱うときに使う。
---

# Git Usage

必要な状態だけを確認し、目的に対応する Git コマンドを実行する。

## 原則

- 変更前に repository root、current branch、dirty 状態を確認する。
- default branch と remote は固定名で推測せず、repository の設定から取得する。
- 新しい作業は ticket ID を含む branch と専用 worktree に分ける。
- 既存の専用 worktree が目的を満たす場合は再利用する。
- commit には意図した path だけを stage する。
- push 前に remote の default branch を fetch し、必要なら current branch を rebase する。
- dirty worktree を自動で stash しない。
- force push、branch 削除、worktree 削除、`git reset --hard` はユーザーの明示的な依頼なしに実行しない。

## コマンドの選択

- 状態確認：`git status --short --branch`、`git diff`、`git diff --staged`
- worktree 作成：`git wt` を優先し、利用できなければ `git worktree add`
- branch 作成：既存 branch と衝突しないことを確認して `git switch -c`
- commit：対象 path を `git add` してから `git commit`
- remote 更新：`git fetch <remote>`
- default branch 更新：default branch の worktree で `git pull --ff-only`
- rebase：clean な作業 branch で `git rebase <remote>/<default-branch>`
- push：`git push -u <remote> <branch>`

## branch 名

repository に規約があれば優先する。
規約がなければ `<type>/<ticket-id>/<short-description>` とし、`type` は `feature`、`hotfix`、`chore` から選ぶ。
ticket ID が未確定の検証作業だけ `wip/<short-description>` を使う。

状態変更前に、対象、主要コマンド、停止条件をユーザーへ短く示す。
