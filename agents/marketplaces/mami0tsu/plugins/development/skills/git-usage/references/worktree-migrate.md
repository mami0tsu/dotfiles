# Worktree Migrate

primary worktreeで開始した未commitの作業を専用worktreeへ移す。
移送後はprimary worktreeをcleanなdefault branchへ戻し、作業branchと変更を専用worktreeに残す。

## やること

1. 移送元の状態を記録する
2. stage済み変更をunstageする
3. 一時branchと専用worktreeを作成する
4. tracked変更を適用する
5. 移送結果を照合する
6. primary worktreeをcleanにする
7. branchの配置を確定する

### 1. 移送元の状態を記録する

現在地がprimary worktreeであり、current branchがdefault branchではないことを確認する。
Worktree Listに従い、default branchが別のworktreeに割り当てられていないことも確認する。

```sh
git rev-parse --path-format=absolute --git-dir
git rev-parse --path-format=absolute --git-common-dir
git status --short --branch
git diff --cached --name-only
git diff --name-only
git ls-files --others --exclude-standard
git ls-tree -r HEAD
git ls-files --stage
git submodule foreach --recursive 'git status --porcelain=v1'
```

primary worktreeでは、absolute pathへ変換したgit directoryとcommon directoryが同じになる。
current branch、stage済みpath、tracked変更path、未追跡pathを記録する。
変更pathについてHEAD treeとindexのmodeを確認し、どちらかが `160000`のgitlinkである場合は停止する。
submodule内のstatusに変更がある場合も停止する。

### 2. stage済み変更をunstageする

記録したstage済みpathだけをunstageする。
移送先ではすべての変更を未stageにするため、stage状態は再現しない。

```sh
git restore --staged -- <staged-path>...
git status --short --branch
```

unstage後のstatus、tracked変更path、未追跡pathを移送元の基準として記録する。

### 3. 一時branchと専用worktreeを作成する

作業branchのHEADを起点に一時branchを作り、未追跡ファイルを専用worktreeへコピーする。

```sh
git wt --nocd --copyuntracked \
  -b <temporary-branch> <worktree> <working-branch>
```

ignore対象は、利用者がコピーを明示した場合だけ `--copyignored` を追加する。
コマンドが返すabsolute pathを移送先として記録する。

### 4. tracked変更を適用する

移送元のtracked変更をbinary patchとして移送先へ適用する。

```sh
git diff --binary --no-ext-diff | git -C <target-path> apply
```

patchの適用に失敗した場合は、primary worktreeのcleanupへ進まない。

### 5. 移送結果を照合する

移送元と移送先で、statusとtracked差分が一致することを確認する。

```sh
git status --porcelain=v1
git -C <target-path> status --porcelain=v1
git diff --binary --no-ext-diff
git -C <target-path> diff --binary --no-ext-diff
```

未追跡pathは一覧が一致することを確認し、各ファイルの内容を `cmp` で比較する。

```sh
git ls-files --others --exclude-standard
git -C <target-path> ls-files --others --exclude-standard
cmp <source-path>/<untracked-path> <target-path>/<untracked-path>
```

ignore対象をコピーした場合は、`git ls-files --others --ignored --exclude-standard` で対象pathを取得し、同じ方法で内容を比較する。
内容が一致しない場合はcleanupへ進まない。

### 6. primary worktreeをcleanにする

cleanup直前に移送元と移送先のstatus、diff、未追跡ファイル、コピーしたignore対象を再取得する。
双方が手順5の内容から変化せず、互いに一致することを確認する。
一致した場合だけ、記録済みpathを明示してtracked変更を復元し、未追跡ファイルを削除する。
ignore対象をコピーした場合は、明示されたpathだけをprimary worktreeから削除する。

```sh
git restore --worktree -- <tracked-path>...
git clean -fd -- <untracked-path>...
git clean -fdX -- <ignored-path>...
git status --short --branch
test ! -e <source-path>/<ignored-path>
test ! -L <source-path>/<ignored-path>
```

ignore対象をコピーしていない場合は、`git clean -fdX`を実行しない。
primary worktreeがcleanにならない場合はbranchを切り替えない。

### 7. branchの配置を確定する

primary worktreeをdefault branchへ戻す。
次に、移送先を一時branchから本来の作業branchへ切り替え、一時branchを削除する。

```sh
git switch <default-branch>
git -C <target-path> switch <working-branch>
git branch -d <temporary-branch>
```

最後に、primary worktreeがcleanなdefault branch、移送先が作業branchで全変更が未stageであることを確認する。

```sh
git status --short --branch
git -C <target-path> status --short --branch
```

## やらないこと

- primary worktree以外からmigrationを開始しない
- default branchまたはremoteを名前から推測しない
- submoduleの変更を移送しない
- 利用者の明示なしにignore対象をコピーしない
- sourceとtargetのstatus、diff、未追跡ファイル、コピーしたignore対象が一致する前にcleanupしない
- pathを省略した `git restore` や `git clean` を実行しない
- cleanup後もprimary worktreeがdirtyな場合にbranchを切り替えない
- 一時branch以外のbranchを削除しない

## 参考情報

- 公式リポジトリ：[k1LoW/git-wt](https://github.com/k1LoW/git-wt)
