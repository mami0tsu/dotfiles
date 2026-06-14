# create-branch

現在の base branch worktree を、新しい作業 branch に切り替える。

worktree を分けて並行作業したい場合は `create-worktree` を使う。

## 前提

- 現在の worktree が local base branch を checkout している
- 現在の worktree が clean
- 通常 branch には ticket-id がある
- ticket-id がない場合は `wip/` branch として明示的に作る

## 手順

1. `common/context.md`、`common/safety.md`、`common/naming.md`、`common/execution-plan.md` を読む。
2. repository root、現在 branch、remote default branch、local base branch を取得する。
3. 現在 branch が local base branch と一致しなければ止める。
4. `git status --short` で dirty なら止める。
5. ticket-id と short-description を決める。
6. branch 名の local/remote 衝突を確認する。
7. 実行計画を表示する。
8. local base branch を fast-forward 更新する。
9. local base branch から新 branch を作成する。

## コマンド

```sh
git pull --ff-only
git switch -c <branch-name> <local-base-branch>
```

既存規約がない場合の branch 名:

```text
<type>/<ticket-id>/<short-description>
wip/<short-description>
```
