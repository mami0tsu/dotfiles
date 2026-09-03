# autosquash-commits

未公開のfixup commitをfixup先へまとめ、関心ごとのcommitへ整理する[^git-rebase]。

## 入力

- repositoryのpath
- base commit
- target commit

## 出力

- 整理前のtarget commit
- 整理後のtarget commit
- 整理後のcommit
- 整理前後の差分
- status

## 制約

- target commitは現在のbranchのHEADと一致させる。
- worktreeとstage済みの状態はcleanとする。
- base commitからtarget commitまでのcommitはremoteへ未公開とする。
- base commitからtarget commitまでにmerge commitを含めない。
- fixup先がbase commitからtarget commitまでに含まれない場合は実行しない。
- fixup先のcommit messageの1行目は、base commitからtarget commitまでで重複させない。
- `--autostash`と`--no-verify`を使わない。

## 手順

### 1. Commitを確認する

```sh
git -C <repository-path> rev-parse --verify <base-commit>^{commit}
git -C <repository-path> rev-parse --verify <target-commit>^{commit}
git -C <repository-path> merge-base --is-ancestor <base-commit> <target-commit>
git -C <repository-path> rev-list --merges <base-commit>..<target-commit>
git -C <repository-path> log --format='%H%x09%s' <base-commit>..<target-commit>
git -C <repository-path> status --porcelain=v1 --branch
```

### 2. Commitを整理する

```sh
GIT_SEQUENCE_EDITOR=: git -C <repository-path> rebase --interactive --autosquash <base-commit>
```

conflictが発生した場合は自動で解消せず、次のコマンドでrebase前の状態へ戻す。

```sh
git -C <repository-path> rebase --abort
```

### 3. ファイル内容を比較する

```sh
git -C <repository-path> diff --exit-code <target-commit> HEAD
git -C <repository-path> diff --check <base-commit>..HEAD
```

### 4. 結果を取得する

```sh
git -C <repository-path> log --format=fuller --stat <base-commit>..HEAD
git -C <repository-path> status --porcelain=v1 --branch
```

### 5. 結果を返す

整理前後のtarget commit、整理後のcommit、整理前後の差分、statusを返す。
整理前後のファイル内容が異なる場合は成功として返さない。

[^git-rebase]: [Git `rebase` manual](https://git-scm.com/docs/git-rebase)
