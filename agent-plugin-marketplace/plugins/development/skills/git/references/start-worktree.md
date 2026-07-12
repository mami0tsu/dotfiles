# start-worktree

新しい worktree と branch を作成する。
開発フローで新しい作業を始めるときの標準 runbook。

## 前提

- [rule-safety.md](rule-safety.md) と [rule-naming.md](rule-naming.md) を読む
- 上位 skill から ticket-id、branch type、short-description が渡されている
- base branch worktree が存在する
- base branch worktree が clean
- base branch worktree で local base branch を fast-forward 更新できる

ticket-id がない場合は [rule-naming.md](rule-naming.md) に従い、`wip/<short-description>` として明示的に作る。

## 確認コマンド

repository root:

```sh
git rev-parse --show-toplevel
```

remote base branch:

```sh
git rev-parse --verify origin/main
```

worktree:

```sh
git worktree list --porcelain
git status --short --branch
```

branch 衝突:

```sh
git show-ref --verify --quiet refs/heads/<branch-name>
git show-ref --verify --quiet refs/remotes/origin/<branch-name>
```

`git wt` 設定:

```sh
git config --get wt.basedir
git config --get wt.nocd
```

## 実行前に表示する項目

- repository root
- remote base branch: `origin/main`
- local base branch: `main`
- base branch worktree path
- base branch worktree の dirty 状態
- branch name
- worktree name または worktree path
- 実行する主要コマンド
- 停止条件

## 実行コマンド

base branch worktree で local base branch を更新する:

```sh
git pull --ff-only
```

`git wt` が使える場合は優先する:

```sh
git wt --nocd -b <branch-name> <worktree-name> main
```

`git wt` が使えない場合は標準 Git に fallback する:

```sh
git worktree add -b <branch-name> <worktree-path> main
```
