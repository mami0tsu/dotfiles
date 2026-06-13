# update-local-base-branch

local base branch を remote default branch に fast-forward 更新する。

## 前提

- 対象は local base branch を checkout している worktree
- 対象 worktree が dirty なら止める
- fast-forward できない場合は止める
- merge commit は作らない

## 手順

1. `common/context.md` と `common/safety.md` を読む。
2. remote default branch と local base branch を解決する。
3. local base branch を checkout している worktree path を探す。
4. 見つからなければ止める。
5. 対象 worktree が dirty なら path と dirty 状態を表示して止める。
6. 対象 worktree で `git pull --ff-only` を実行する。

## コマンド

対象 worktree で実行する:

```sh
git pull --ff-only
```
