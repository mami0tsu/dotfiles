# compare-commits

指定したbase commitとtarget commitの差分を取得する[^git-diff]。

## 入力

- repositoryのpath
- base commit
- target commit

## 出力

- 変更済みpath
- diff stat
- diff
- 空白文字のエラー

## 制約

- base commitとtarget commitを省略しない。
- 比較対象をbranch名から推測しない。
- repositoryのstateを変更しない。

## 手順

### 1. Commitを確認する

```sh
git -C <repository-path> rev-parse --verify <base-commit>^{commit}
git -C <repository-path> rev-parse --verify <target-commit>^{commit}
```

### 2. 差分を取得する

```sh
git -C <repository-path> diff --check <base-commit>..<target-commit>
git -C <repository-path> diff --name-status <base-commit>..<target-commit>
git -C <repository-path> diff --stat <base-commit>..<target-commit>
git -C <repository-path> diff <base-commit>..<target-commit>
```

### 3. 結果を返す

解決したcommit、変更済みpath、diff stat、diff、空白文字のエラーを返す。

[^git-diff]: [Git `diff` manual](https://git-scm.com/docs/git-diff)
