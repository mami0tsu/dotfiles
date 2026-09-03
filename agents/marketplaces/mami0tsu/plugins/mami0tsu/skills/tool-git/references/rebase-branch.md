# rebase-branch

現在の作業branchを指定したremote branchへrebaseする[^git-rebase]。

## 入力

- repositoryのpath
- remote
- remote branch

## 出力

- rebase結果
- 作業branchのcommit
- status

## 制約

- current branchはdefault branch以外とする。
- worktreeはcleanとする。
- 作業branchのcommitはremoteへ未公開とする。
- conflictを自動で解消しない。

## 手順

### 1. Rebase前の状態を取得する

```sh
git -C <repository-path> status --porcelain=v1 --branch
git -C <repository-path> log --oneline HEAD..<remote>/<remote-branch>
```

### 2. Branchをrebaseする

```sh
git -C <repository-path> rebase <remote>/<remote-branch>
```

### 3. Rebase後の状態を取得する

```sh
git -C <repository-path> status --porcelain=v1 --branch
git -C <repository-path> log --oneline <remote>/<remote-branch>..HEAD
```

### 4. 結果を返す

rebase結果、作業branchに残ったcommit、statusを返す。

[^git-rebase]: [Git `rebase` manual](https://git-scm.com/docs/git-rebase)
