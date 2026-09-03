# switch-worktree

既存worktreeのabsolute pathを取得し、後続コマンドの実行先を確定する[^git-wt]。

## 入力

- repositoryのpath
- `list-worktrees`ユースケースが返したbranchまたはpath

## 出力

- worktreeのabsolute path
- branch
- status

## 制約

- `list-worktrees`ユースケースに含まれるbranchまたはpathだけを使う。
- shellのcurrent directoryが後続コマンドへ引き継がれると判断しない。
- worktreeとbranchを作成しない。

## 手順

### 1. Worktreeのpathを取得する

```sh
git -C <repository-path> wt --nocd <branch-or-path>
```

### 2. 実行先を確認する

```sh
git -C <worktree-path> rev-parse --show-toplevel
git -C <worktree-path> branch --show-current
git -C <worktree-path> status --porcelain=v1 --branch
```

### 3. 結果を返す

worktreeのabsolute path、branch、statusを返す。

[^git-wt]: [k1LoW/git-wt](https://github.com/k1LoW/git-wt)
