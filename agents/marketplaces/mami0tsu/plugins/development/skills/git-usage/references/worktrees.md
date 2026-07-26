# 専用 worktree

## 情報源

- 公式ドキュメント：[git-worktree](https://git-scm.com/docs/git-worktree)、[git-branch](https://git-scm.com/docs/git-branch)、[git-status](https://git-scm.com/docs/git-status)、[git-fetch](https://git-scm.com/docs/git-fetch)、[git-switch](https://git-scm.com/docs/git-switch)
- 検証バージョン：`git version 2.55.0`
- 確認コマンド：`git --version`、`git worktree add --help`、`git worktree list --help`、`git branch --help`、`git status --help`、`git fetch --help`、`git switch --help`

## worktree を作成する

### 目的

既存の作業を変更せず、新しい branch を checkout した専用の作業場所を作る。

### 前提条件

親 repository の場所、作成先 path、branch 名、起点の `<remote>/<default-branch>` を確認済みである。

作成先 path が空であることを確認する。

default branch を起点にする場合は、先に `git fetch <remote>` を実行して remote-tracking branch を更新する。

### 推奨コマンド

親 repository で実行する。

```sh
git worktree list --porcelain
git branch --list '<branch>'
git worktree add -b <branch> <path> <remote>/<default-branch>
git -C <path> status --short --branch
```

既存 branch を明示的に再利用する場合だけ、`-b <branch>` を外して `git worktree add <path> <branch>` を使う。

### 結果の確認

`git worktree list --porcelain` に `<path>` と `<branch>` が表示されることを確認する。

`git -C <path> status --short --branch` が意図した branch と clean な状態を示すことを確認する。

### 停止条件

作成先 path が空でない場合、既存の内容を削除や上書きしない。

同じ branch が別の worktree で checkout 済みの場合、`--force` や `--ignore-other-worktrees` を使わない。

既存 branch を再利用するか、新しい branch 名を選ぶかを利用者へ確認する。

起点の remote や default branch を確定できない場合は、推測で作成しない。

### 代表的な失敗

`'<branch>' is already used by worktree at '<path>'` は同じ branch を複数の worktree で checkout しようとしたことを示す。

`git worktree list --porcelain` で branch の worktree を特定し、別 branch を作るか利用者へ確認する。

`fatal: '<path>' already exists` は作成先 path が利用できないことを示す。

別の空 path を選ぶ。
