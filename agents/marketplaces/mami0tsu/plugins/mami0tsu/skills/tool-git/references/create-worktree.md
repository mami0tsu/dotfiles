# create-worktree

指定した起点から新しいbranchとworktreeを作る[^git-wt]。

## 入力

- repositoryのpath
- 起点
- 新しいbranch名
- 新しいworktree名

## 出力

- 作成したbranch
- 作成したworktreeのpath
- 作成したworktreeのHEAD

## 制約

- branch名はrepository内で未使用とする。
- worktree名はrepository内で未使用とする。
- fileのcopy optionを有効にしない。
- 既存のbranchとworktreeを変更しない。

## 手順

### 1. Start pointを確認する

```sh
git -C <repository-path> rev-parse --verify <start-point>^{commit}
```

### 2. Worktreeを作る

```sh
git -C <repository-path> wt --nocd \
  --copyignored=false --copyuntracked=false --copymodified=false \
  -b <branch> <worktree-name> <start-point>
```

### 3. 作成結果を取得する

```sh
git -C <repository-path> wt --json
```

### 4. 結果を返す

JSONから作成したbranch、worktreeのpath、HEADを返す。

[^git-wt]: [k1LoW/git-wt](https://github.com/k1LoW/git-wt)
