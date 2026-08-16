# 状態確認と branch

## 情報源

- 公式ドキュメント：[git-rev-parse](https://git-scm.com/docs/git-rev-parse)、[git-status](https://git-scm.com/docs/git-status)、[git-diff](https://git-scm.com/docs/git-diff)、[git-switch](https://git-scm.com/docs/git-switch)、[git-branch](https://git-scm.com/docs/git-branch)、[git-worktree](https://git-scm.com/docs/git-worktree)
- 検証バージョン：`git version 2.55.0`
- 確認コマンド：`git --version`、`git rev-parse --help`、`git status --help`、`git diff --help`、`git switch --help`、`git branch --help`、`git worktree list --help`

## 状態確認

### 目的

現在の branch、upstream との関係、未 stage の変更、stage 済みの変更を区別する。

### 前提条件

Git repository 内で実行する。

repository root が不明なら、先に `git rev-parse --show-toplevel` を実行する。

### 推奨コマンド

```sh
git status --short --branch
git diff --check
git diff
git diff --staged
```

`git status --short --branch` の先頭行で branch と upstream を確認する。

`git diff` は worktree と index の差分を示す。

`git diff --staged` は次の commit に入る差分を示す。

`git diff --check` は末尾空白や conflict marker を含む不正な patch を検出する。

### 結果の確認

対象 path が untracked、未 stage、stage 済みのどれかを `git status --short --branch` と2つの diff で説明できる状態にする。

### 停止条件

`UU`、`AA`、`DD` など unmerged 状態が表示された場合は、merge、rebase、cherry-pick の進行中である可能性があるため変更を続けず利用者へ確認する。

意図しない変更、secret、生成物が表示された場合も stage や branch 切替を続けない。

### 代表的な失敗

`git diff` が空でも、`git status` に残る変更はすでに stage 済みの可能性がある。

`git diff --staged` を実行して確認する。

status に upstream が表示されない場合は、push 前に remote と branch を明示して upstream を設定する必要がある。

## 新しい branch

### 目的

現在の commit を起点に、既存 branch と衝突しない作業 branch を作成して切り替える。

### 前提条件

現在の branch、変更済み path、起点にする commit を確認済みである。

新しい作業を隔離するなら、branch 単体ではなく [worktree](worktree-create.md) を使う。

### 推奨コマンド

```sh
git branch --list '<branch>'
git switch -c <branch> <start-point>
git status --short --branch
```

`<start-point>` を省略すると current `HEAD` を起点にする。

default branch の最新 commit を起点にする場合は、先に fetch して `<remote>/<default-branch>` を指定する。

### 結果の確認

`git status --short --branch` の先頭行が新しい branch を示し、`git branch --show-current` の出力が `<branch>` と一致することを確認する。

### 停止条件

同名 branch が存在する場合は上書きや reset を行わず、既存 branch を再利用するか別名にするかを利用者へ確認する。

branch が別の worktree で checkout 済みの場合は、その worktree を確認せず `--ignore-other-worktrees` を使わない。

未確認の変更が current worktree にある場合は、branch 切替によって変更を失うおそれがないことを確認できるまで進めない。

### 代表的な失敗

`fatal: a branch named '<branch>' already exists` は同名 branch が存在することを示す。

`git branch --list '<branch>'` と `git worktree list --porcelain` で所有状況を確認する。

`Your local changes ... would be overwritten by switch` は切替先が変更を上書きすることを示す。

変更を退避する方法を利用者が選ぶまで停止する。
