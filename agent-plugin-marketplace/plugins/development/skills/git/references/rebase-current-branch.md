# rebase-current-branch

現在 branch を `origin/main` に rebase する。

## 前提

- [rule-safety.md](rule-safety.md) を読む
- rebase 先は `origin/main`
- local `main` は更新しない
- rebase 前に `git fetch origin` を実行する
- detached HEAD では実行しない

## 確認コマンド

```sh
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
```

detached HEAD、base branch 上、dirty worktree なら止める。

## 実行前に表示する項目

- repository root
- current branch
- dirty 状態
- remote base branch: `origin/main`
- 実行する主要コマンド
- 停止条件

## 実行コマンド

```sh
git fetch origin
git rev-parse --verify origin/main
git rebase origin/main
```

例:

```sh
git rebase origin/main
```
