# fetch-remote-base

remote の情報を更新する。local base branch は切り替えず、更新もしない。

## 使う場面

- `rebase-current-branch` の前に `origin/main` などを最新化する
- local `main` を更新せずに remote default branch だけ最新化したい

## 手順

1. `common/context.md` を読む。
2. repository root を確認する。
3. fetch する。
4. remote default branch を解決する。

## コマンド

```sh
git fetch origin
git symbolic-ref --short refs/remotes/origin/HEAD
```
