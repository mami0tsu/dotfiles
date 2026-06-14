# 実行計画

次の操作では、実行前に計画を表示する。

- `create-branch`
- `create-worktree`
- `push-branch`
- `rebase-current-branch`
- `promote-wip-branch`

表示する内容:

- repository root
- 現在の branch
- 対象 branch
- base branch または base ref
- 対象 worktree path
- dirty 状態
- 実行する主要コマンド
- ユーザー確認が必要な理由

`fetch-remote-base` や通常の `switch-branch` では、原則として実行計画は不要。ただし dirty worktree、履歴変更、push を伴う場合は表示する。
