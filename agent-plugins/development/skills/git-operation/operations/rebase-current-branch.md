# rebase-current-branch

現在 branch を remote default branch に rebase する。

## 前提

- rebase 先は `origin/HEAD` から解決した remote default branch
- local base branch は更新しない
- rebase 前に `git fetch origin` を実行する
- detached HEAD では実行しない

## 手順

1. `common/context.md`、`common/safety.md`、`common/execution-plan.md` を読む。
2. 現在 branch を取得する。
3. detached HEAD または base branch 上なら止める。
4. dirty なら止める。
5. `git fetch origin` を実行する。
6. remote default branch を解決する。
7. 実行計画を表示する。
8. rebase する。

## コマンド

```sh
git fetch origin
git rebase <remote-default-branch>
```

例:

```sh
git rebase origin/main
```
