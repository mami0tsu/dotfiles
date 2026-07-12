# update-local-base

local base branch `main` を `origin/main` に fast-forward 更新する。

## 前提

- [rule-safety.md](rule-safety.md) を読む
- 対象は `main` を checkout している worktree
- 対象 worktree が dirty なら止める
- fast-forward できない場合は止める
- merge commit は作らない

## 確認コマンド

```sh
git rev-parse --show-toplevel
git rev-parse --verify origin/main
git worktree list --porcelain
```

`main` を checkout している worktree がなければ止める。
対象 worktree で dirty 状態を確認する:

```sh
git status --short --branch
```

## 実行前に表示する項目

- repository root
- remote base branch: `origin/main`
- local base branch: `main`
- base branch worktree path
- dirty 状態
- 実行する主要コマンド
- 停止条件

## 実行コマンド

対象 worktree で実行する:

```sh
git pull --ff-only
```
