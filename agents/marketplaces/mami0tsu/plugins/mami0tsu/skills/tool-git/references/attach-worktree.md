# attach-worktree

既存branchへ新しいworktreeを関連付ける[^git-wt]。

## 入力

- repositoryのpath
- 既存branch
- 新しいworktree名

## 出力

- worktreeのabsolute path
- branch
- HEAD

## 制約

- branchはどのworktreeにも割り当てられていないものとする。
- worktree名はrepository内で未使用とする。
- fileのcopy optionを有効にしない。

## 手順

### 1. Branchを確認する

```sh
git -C <repository-path> rev-parse --verify <branch>^{commit}
git -C <repository-path> wt --json --nocd
```

### 2. Worktreeを関連付ける

```sh
git -C <repository-path> wt --nocd \
  --copyignored=false --copyuntracked=false --copymodified=false \
  -b <branch> <worktree-name>
```

### 3. 結果を取得する

```sh
git -C <repository-path> wt --json --nocd
```

### 4. 結果を返す

JSONからworktreeのabsolute path、branch、HEADを返す。

[^git-wt]: [k1LoW/git-wt](https://github.com/k1LoW/git-wt)
