# inspect-push

指定したbranchのpushによるremote branchの変更をdry-runで確認する[^git-push]。

## 入力

- repositoryのpath
- remote
- local branch
- remote branch

## 出力

- remote URL
- pushのdry-run結果

## 制約

- local branchとremote branchを省略しない。
- force pushのoptionを使わない。
- local repositoryとremote repositoryのstateを変更しない。

## 手順

### 1. Branchとremoteを確認する

```sh
git -C <repository-path> rev-parse --verify <local-branch>^{commit}
git -C <repository-path> remote get-url <remote>
```

### 2. Pushを確認する

```sh
git -C <repository-path> push --dry-run --porcelain <remote> <local-branch>:refs/heads/<remote-branch>
```

### 3. 結果を返す

remote URLとpushのdry-run結果を返す。

[^git-push]: [Git `push` manual](https://git-scm.com/docs/git-push)
