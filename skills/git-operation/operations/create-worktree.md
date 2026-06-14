# create-worktree

新しい worktree と branch を作成する。ユーザーが「作業を始める」とだけ言った場合のデフォルト操作。

## 前提

- base branch worktree が存在する
- base branch worktree が clean
- base branch worktree で local base branch を fast-forward 更新できる
- 通常 branch には ticket-id がある
- ticket-id がない場合は `wip/` branch として明示的に作る

## 手順

1. `common/context.md`、`common/safety.md`、`common/naming.md`、`common/execution-plan.md` を読む。
2. repository root、remote default branch、local base branch を取得する。
3. `git worktree list --porcelain` で local base branch を checkout している worktree path を探す。
4. base branch worktree がなければ止める。
5. base branch worktree が dirty なら、path と dirty 状態を表示して止める。
6. ticket-id と short-description を決める。
7. branch 名と worktree 名の local/remote/path 衝突を確認する。
8. 実行計画を表示する。
9. base branch worktree で `git pull --ff-only` を実行する。
10. base branch worktree で worktree を作成する。

## `git wt` 優先

`git wt` が使える場合は優先する。

```sh
git wt --nocd -b <branch-name> <worktree-name> <local-base-branch>
```

`git wt` が使えない場合は標準 Git に fallback する。

```sh
git worktree add -b <branch-name> <worktree-path> <local-base-branch>
```

`git wt` を使う場合、既存設定があれば尊重する。

```sh
git config --get wt.basedir
git config --get wt.nocd
```

この dotfiles では `wt.basedir = ../{gitroot}-worktrees`、`wt.nocd = create` を想定できる。
