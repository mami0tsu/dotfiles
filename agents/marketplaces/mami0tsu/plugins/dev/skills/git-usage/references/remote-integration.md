# remote と履歴を更新する

## 情報源

- 公式ドキュメント：[git-remote](https://git-scm.com/docs/git-remote)、[git-ls-remote](https://git-scm.com/docs/git-ls-remote)、[git-symbolic-ref](https://git-scm.com/docs/git-symbolic-ref)、[git-fetch](https://git-scm.com/docs/git-fetch)、[git-pull](https://git-scm.com/docs/git-pull)、[git-rebase](https://git-scm.com/docs/git-rebase)、[git-push](https://git-scm.com/docs/git-push)、[git-status](https://git-scm.com/docs/git-status)、[git-log](https://git-scm.com/docs/git-log)、[git-diff](https://git-scm.com/docs/git-diff)、[git-branch](https://git-scm.com/docs/git-branch)、[git-rev-parse](https://git-scm.com/docs/git-rev-parse)、[git-add](https://git-scm.com/docs/git-add)
- 検証バージョン：`git version 2.55.0`
- 確認コマンド：`git --version`、`git remote --help`、`git ls-remote --help`、`git symbolic-ref --help`、`git fetch --help`、`git pull --help`、`git rebase --help`、`git push --help`、`git status --help`、`git log --help`、`git diff --help`、`git branch --help`、`git rev-parse --help`、`git add --help`

## remote を fetch する

### 目的

remote の default branch を一次情報から確定し、remote-tracking branch を更新して現在の branch との差分をローカルで確認できるようにする。

### 前提条件

対象 remote を `git remote -v` で確認済みである。

network access と remote の読み取り権限がある。

### 推奨コマンド

```sh
git remote -v
git ls-remote --symref <remote> HEAD
git fetch <remote>
git status --short --branch
```

`git ls-remote --symref <remote> HEAD` の `ref: refs/heads/<default-branch> HEAD` から default branch を確認する。

たとえば `ref: refs/heads/main HEAD` が出力された場合、以降は `<remote>/main` を default branch として使う。

`refs/remotes/<remote>/HEAD` は過去の fetch が残した remote-tracking ref であり、remote default branch を確定するためには使わない。

### 結果の確認

`git status --short --branch` の ahead、behind、diverged 表示か、`git log --oneline HEAD..<remote>/<default-branch>` で差分を確認する。

### 停止条件

認証失敗、host verification 失敗、想定外の remote URL が出た場合は、credential や URL を変更せず利用者へ確認する。

`git ls-remote --symref` が失敗した場合、または `HEAD` に対応する `refs/heads/` の symref が出力されない場合は、branch 名を推測しない。

remote が symref を提供しない理由を利用者へ確認するまで、fetch、pull、rebase、push を続けない。

### 代表的な失敗

`could not read Username` や permission denied は認証情報または権限が不足していることを示す。

認証方式を利用者へ確認する。

`fatal: not a git repository` は実行場所が Git repository 外であることを示す。

`git rev-parse --show-toplevel` で repository root を確認する。

## default branch を fast-forward で更新する

### 目的

default branch の専用 worktree を、merge commit を作らず remote の先頭へ更新する。

### 前提条件

default branch の worktree にいる。

worktree が clean である。

remote と default branch を fetch 後に確認済みである。

### 推奨コマンド

```sh
git status --short --branch
git pull --ff-only <remote> <default-branch>
git status --short --branch
```

### 結果の確認

`git status --short --branch` に未 commit の変更がなく、local branch が remote の default branch と一致することを確認する。

### 停止条件

worktree が dirty、current branch が default branch ではない、または fast-forward できない場合は停止する。

`--rebase`、`--no-rebase`、`--force` を追加して pull の挙動を変えない。

### 代表的な失敗

`Not possible to fast-forward` は local default branch と remote が分岐していることを示す。

local commit の扱いを利用者へ確認してから、rebase または merge を選ぶ。

## 作業 branch を rebase する

### 目的

作業 branch の local commit を、更新済みの remote default branch の先頭に積み直す。

### 前提条件

current branch が default branch ではない。

worktree が clean である。

`git fetch <remote>` を実行済みで、rebase 対象が `<remote>/<default-branch>` と確定している。

作業 branch の既存 commit が remote へ公開済みではないか、公開済みなら履歴変更と force push を利用者が明示的に許可している。

### 推奨コマンド

```sh
git status --short --branch
git log --oneline HEAD..<remote>/<default-branch>
git rebase <remote>/<default-branch>
git status --short --branch
git log --oneline <remote>/<default-branch>..HEAD
```

### 結果の確認

`git status --short --branch` が clean であることを確認する。

`git log --oneline <remote>/<default-branch>..HEAD` が、rebase 後にも残すべき作業 commit だけを示すことを確認する。

### 停止条件

conflict が発生した場合は、衝突した path と意図を確認するまで解消を続けない。

rebase を取り消す場合は `git rebase --abort` を使う。

rebase 後に remote へ公開済みの branch を更新するには force push が必要になるため、明示的な依頼なしに push しない。

### 代表的な失敗

`CONFLICT` は commit の再適用が停止したことを示す。

解消方針を確認後、対象 path を `git add -- <path>` して `git rebase --continue` を実行する。

解消方針が決まらない場合は `git rebase --abort` を使う。

`cannot rebase: You have unstaged changes` は worktree が clean でないことを示す。

変更を自動で stash せず、利用者が処理方法を選ぶまで停止する。

## 作業 branch を push する

### 目的

確認済みの作業 branch を明示した remote へ公開し、必要なら upstream を設定する。

### 前提条件

current branch、remote、branch 名、公開する commit の範囲を確認済みである。

default branch を fetch 済みで、必要な rebase または同期判断を終えている。

### 推奨コマンド

```sh
git status --short --branch
git log --oneline <remote>/<default-branch>..HEAD
git diff --check <remote>/<default-branch>...HEAD
git push -u <remote> <branch>
git status --short --branch
```

`-u` は新しい branch の upstream を設定する。

すでに正しい upstream がある branch でも、remote と branch を明示して push する。

### 結果の確認

`git status --short --branch` が `<remote>/<branch>` を upstream として表示し、ahead または behind がないことを確認する。

remote の受け入れ結果と表示された URL を確認する。

### 停止条件

current branch が default branch、protected branch、または意図しない branch の場合は push しない。

push する commit に意図しない変更がある場合は停止する。

non-fast-forward rejection が出た場合、`--force` や `--force-with-lease` を使わず利用者へ確認する。

### 代表的な失敗

`rejected ... non-fast-forward` は、local で確認できない commit が remote branch 側にあることを示す。

`git fetch <remote>` を実行し、branch の同期または rebase 方針を利用者へ確認する。

`src refspec <branch> does not match any` は branch 名が誤っているか、push する commit がまだないことを示す。

`git branch --show-current` と `git log -1 --oneline` で確認する。
