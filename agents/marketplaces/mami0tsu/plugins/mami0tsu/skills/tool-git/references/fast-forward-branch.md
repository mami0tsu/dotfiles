# fast-forward-branch

現在のbranchを指定したremote branchへfast-forwardする[^git-merge]。

## 入力

- repositoryのpath
- remote
- remote branch

## 出力

- 更新後のHEAD
- status

## 制約

- current branchは更新対象のbranchとする。
- worktreeはcleanとする。
- merge commitとrebaseを作らない。

## 手順

### 1. 更新前の状態を取得する

```sh
git -C <repository-path> status --porcelain=v1 --branch
git -C <repository-path> rev-parse HEAD
```

### 2. Branchを更新する

```sh
git -C <repository-path> pull --ff-only <remote> <remote-branch>
```

### 3. 更新後の状態を取得する

```sh
git -C <repository-path> rev-parse HEAD
git -C <repository-path> status --porcelain=v1 --branch
```

### 4. 結果を返す

更新前後のHEADと更新後のstatusを返す。

[^git-merge]: [Git `merge` manual](https://git-scm.com/docs/git-merge)
