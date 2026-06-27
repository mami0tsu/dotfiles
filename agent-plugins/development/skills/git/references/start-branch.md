# start-branch

現在の base branch worktree を、新しい作業 branch に切り替える。

worktree を分けて並行作業したい場合は [start-worktree.md](start-worktree.md) を使う。

## 前提

- [rule-safety.md](rule-safety.md) と [rule-naming.md](rule-naming.md) を読む
- 上位 skill から ticket-id、branch type、short-description が渡されている
- 現在の worktree が local base branch を checkout している
- 現在の worktree が clean

ticket-id がない場合は [rule-naming.md](rule-naming.md) に従い、`wip/<short-description>` として明示的に作る。

## 確認コマンド

```sh
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git rev-parse --verify origin/main
git show-ref --verify --quiet refs/heads/<branch-name>
git show-ref --verify --quiet refs/remotes/origin/<branch-name>
```

## 実行前に表示する項目

- repository root
- current branch
- local base branch: `main`
- dirty 状態
- branch name
- 実行する主要コマンド
- 停止条件

## 実行コマンド

```sh
git pull --ff-only
git switch -c <branch-name> main
```

既存規約がない場合の branch 名:

```text
<type>/<ticket-id>/<short-description>
wip/<short-description>
```
