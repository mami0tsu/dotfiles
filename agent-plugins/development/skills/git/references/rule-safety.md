# 安全ルール

## 自動実行しない操作

次の操作はこの skill では自動実行しない。

- `git reset --hard`
- force push
- branch delete
- worktree delete
- remote branch delete
- GitHub CLI/API 操作
- dirty worktree に対する自動 stash

必要になった場合は、別操作としてユーザーに明示確認する。

## dirty worktree

`start-branch`、`start-worktree`、`update-local-base`、`rebase-current-branch`、`promote-wip-branch` では、対象 worktree が dirty なら止める。
stash や commit は自動実行しない。

`commit-changes` では dirty 状態を表示する。
ユーザー指定がない場合は staged 変更だけ commit し、unstaged/untracked は自動で stage しない。

## `wip/` branch

`wip/` branch は ticket-id 作成前の検証や叩き台用。
push は許可するが、通常 PR 化や merge は不可。
Draft PR 作成は別 skill の責務とする。

## rebase と rewrite

`rebase-current-branch` と `promote-wip-branch` は履歴に影響する。
実行前に対象 branch、base、対象 commit、実行コマンドを表示する。

`promote-wip-branch` の commit message rewrite は、新しい ticket-id 付き branch として push する前に local history を整えるための操作とする。
既存 remote `wip/` branch へ force push しない。
