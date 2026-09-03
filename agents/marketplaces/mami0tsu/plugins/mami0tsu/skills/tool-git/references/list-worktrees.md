# list-worktrees

指定したrepositoryに登録されたworktreeを取得する[^git-wt]。

## 入力

- repositoryのpath

## 出力

- 各worktreeのpath
- 各worktreeのbranch
- 各worktreeのHEAD

## 制約

- worktreeをprune、remove、moveしない。
- repositoryのstateを変更しない。

## 手順

### 1. Worktreeを取得する

```sh
git -C <repository-path> wt --json
```

### 2. 結果を返す

JSONから各worktreeのpath、branch、HEADを返す。

[^git-wt]: [k1LoW/git-wt](https://github.com/k1LoW/git-wt)
