# create-branch

指定した起点から新しいbranchを作り、現在のworktreeで切り替える[^git-switch]。

## 入力

- repositoryのpath
- 起点
- 新しいbranch名

## 出力

- branch
- HEAD
- status

## 制約

- 新しいbranch名はrepository内で未使用とする。
- 起点を省略しない。
- current worktreeの変更を上書きしない。

## 手順

### 1. Start pointを確認する

```sh
git -C <repository-path> rev-parse --verify <start-point>^{commit}
git -C <repository-path> branch --list '<branch>'
```

### 2. Branchを作る

```sh
git -C <repository-path> switch -c <branch> <start-point>
```

### 3. 結果を取得する

```sh
git -C <repository-path> branch --show-current
git -C <repository-path> rev-parse HEAD
git -C <repository-path> status --porcelain=v1 --branch
```

### 4. 結果を返す

branch、HEAD、statusを返す。

[^git-switch]: [Git `switch` manual](https://git-scm.com/docs/git-switch)
