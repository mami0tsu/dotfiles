# unstage-changes

指定したpathをindexから外し、worktreeの変更として残す[^git-restore]。

## 入力

- repositoryのpath
- stage済みpath

## 出力

- stage済みの差分
- 未stageの差分
- status

## 制約

- 入力されたpathだけをunstageする。
- worktreeの内容を変更しない。

## 手順

### 1. Stage済みの差分を確認する

```sh
git -C <repository-path> diff --staged -- <path>...
```

### 2. Pathをunstageする

```sh
git -C <repository-path> restore --staged -- <path>...
```

### 3. 結果を取得する

```sh
git -C <repository-path> diff --staged
git -C <repository-path> diff -- <path>...
git -C <repository-path> status --porcelain=v1
```

### 4. 結果を返す

stage済みの差分、未stageの差分、statusを返す。

[^git-restore]: [Git `restore` manual](https://git-scm.com/docs/git-restore)
