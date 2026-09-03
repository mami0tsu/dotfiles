# inspect-changes

指定したrepositoryの未stage、stage済み、untrackedの変更を取得する[^git-status]。

## 入力

- repositoryのpath

## 出力

- 変更済みpath
- 未stageの差分
- stage済みの差分
- 空白文字のエラー

## 制約

- repositoryのstateを変更しない。
- untracked fileの内容を差分へ追加しない。

## 手順

### 1. 変更済みpathを取得する

```sh
git -C <repository-path> status --porcelain=v1
```

### 2. 未stageの差分を取得する

```sh
git -C <repository-path> diff --check
git -C <repository-path> diff
```

### 3. Stage済みの差分を取得する

```sh
git -C <repository-path> diff --staged --check
git -C <repository-path> diff --staged
```

### 4. 結果を返す

各pathのstatus、未stageの差分、stage済みの差分、空白文字のエラーを返す。

[^git-status]: [Git `status` manual](https://git-scm.com/docs/git-status)
