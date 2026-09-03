# commit-fixup

指定したpathを既存commitのfixup commitへ記録する[^git-commit]。

## 入力

- repositoryのpath
- commitへ含めるpath
- fixup先のcommit

## 出力

- fixup commitのhash
- fixup先のcommit
- commitへ記録したpath
- commit後のstatus

## 制約

- 1回の実行で1つのfixup commitだけを作る。
- `git add -A`と`git commit -a`を使わない。
- `--no-verify`と`--amend`を使わない。
- 入力にないpathをstageしない。

## 手順

### 1. Fixup先を確認する

```sh
git -C <repository-path> rev-parse --verify <fixup-target>^{commit}
```

### 2. Pathをstageする

```sh
git -C <repository-path> add -- <path> [<path>...]
```

### 3. Stage済みの差分を取得する

```sh
git -C <repository-path> diff --staged --check
git -C <repository-path> diff --staged --name-status
git -C <repository-path> diff --staged
```

### 4. Fixup commitを作る

```sh
git -C <repository-path> commit --fixup=<fixup-target>
```

### 5. Commitを取得する

```sh
git -C <repository-path> show --format=fuller --stat HEAD
git -C <repository-path> status --porcelain=v1 --branch
```

### 6. 結果を返す

fixup commitのhash、fixup先のcommit、記録したpath、commit後のstatusを返す。

[^git-commit]: [Git `commit` manual](https://git-scm.com/docs/git-commit)
