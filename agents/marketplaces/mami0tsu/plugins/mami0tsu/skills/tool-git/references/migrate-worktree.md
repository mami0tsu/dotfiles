# migrate-worktree

primary worktreeの未commit変更を専用worktreeへ移す[^git-worktree-migration]。

## 入力

- primary worktreeのpath
- working branch
- default branch
- temporary branch
- 新しいworktree名
- trackedの変更済みpath
- untracked path

## 出力

- cleanなprimary worktree
- 変更を保持した専用worktree
- 専用worktreeのabsolute path

## 制約

- primary worktreeでworking branchをcheckout済みとする。
- stage済み変更は`unstage-changes`ユースケースで解消済みとする。
- submodule、gitlink、ignore対象を移送しない。
- default branchは別のworktreeへ割り当てられていないものとする。
- cleanupには入力されたpathだけを使う。

## 手順

### 1. 移送元を確認する

```sh
git -C <primary-path> rev-parse --path-format=absolute --git-dir
git -C <primary-path> rev-parse --path-format=absolute --git-common-dir
git -C <primary-path> status --porcelain=v1 --branch
git -C <primary-path> diff --cached --quiet
git -C <primary-path> ls-tree -r HEAD
git -C <primary-path> ls-files --stage
git -C <primary-path> submodule foreach --recursive 'git status --porcelain=v1'
```

### 2. 専用worktreeを作る

```sh
git -C <primary-path> wt --nocd --copyuntracked \
  -b <temporary-branch> <worktree-name> <working-branch>
```

### 3. Tracked変更を適用する

```sh
git -C <primary-path> diff --binary --no-ext-diff | \
  git -C <target-path> apply
```

### 4. 移送結果を取得する

```sh
git -C <primary-path> status --porcelain=v1
git -C <target-path> status --porcelain=v1
git -C <primary-path> diff --binary --no-ext-diff
git -C <target-path> diff --binary --no-ext-diff
git -C <primary-path> ls-files --others --exclude-standard
git -C <target-path> ls-files --others --exclude-standard
```

### 5. Primary worktreeをcleanにする

```sh
git -C <primary-path> restore --worktree -- <tracked-path>...
git -C <primary-path> clean -fd -- <untracked-path>...
git -C <primary-path> status --porcelain=v1 --branch
```

### 6. Branchの配置を確定する

```sh
git -C <primary-path> switch <default-branch>
git -C <target-path> switch <working-branch>
git -C <primary-path> branch -d <temporary-branch>
```

### 7. 結果を返す

```sh
git -C <primary-path> status --porcelain=v1 --branch
git -C <target-path> status --porcelain=v1 --branch
```

primary worktreeと専用worktreeのpath、branch、変更済みpathを返す。

[^git-worktree-migration]: [k1LoW/git-wt](https://github.com/k1LoW/git-wt)、[Git `diff` manual](https://git-scm.com/docs/git-diff)、[Git `apply` manual](https://git-scm.com/docs/git-apply)
