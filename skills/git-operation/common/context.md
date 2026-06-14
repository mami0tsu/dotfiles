# Git 状態の取得

Git 操作に必要な情報は推測せず、コマンドで取得する。

## 基本情報

```sh
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
```

remote default branch は `origin/HEAD` から解決する。

```sh
git symbolic-ref --short refs/remotes/origin/HEAD
```

失敗した場合は、順に存在確認する。

```sh
git rev-parse --verify origin/main
git rev-parse --verify origin/master
```

`origin/main` のような remote default ref から、対応する local base branch 名を得る。例: `origin/main` -> `main`。

## worktree 情報

標準 Git で確認する:

```sh
git worktree list --porcelain
```

`git wt` が使える場合は、補助情報として使ってよい。

```sh
git wt --json
git config --get wt.basedir
git config --get wt.nocd
```

ただし、`git wt` が使えない環境では標準の `git worktree` に fallback する。

## branch 存在確認

local branch:

```sh
git show-ref --verify --quiet refs/heads/<branch-name>
```

remote branch:

```sh
git show-ref --verify --quiet refs/remotes/origin/<branch-name>
```

## base branch worktree

base branch worktree とは、`main` などの local base branch が checkout されている worktree を指す。

`create-worktree` では、現在位置に関係なく base branch worktree を探し、そこで local base branch を更新してから新しい worktree を作る。

`create-branch` では、現在の worktree が local base branch を checkout している場合だけ実行する。
