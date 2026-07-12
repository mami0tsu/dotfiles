# fetch-remote-base

remote base branch を更新する。
local base branch は切り替えず、更新もしない。

## 使う場面

- `rebase-current-branch` の前に `origin/main` を最新化する
- local `main` を更新せずに `origin/main` だけ最新化する

## 前提

- local branch は更新しない
- worktree の dirty 状態に関係なく実行してよい

## 確認コマンド

```sh
git rev-parse --show-toplevel
```

## 実行コマンド

```sh
git fetch origin
git rev-parse --verify origin/main
```
