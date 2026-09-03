# commit-changes

指定したpathを1つのcommitへ記録する[^git-commit]。

## 入力

- repositoryのpath
- commitへ含めるpath
- Conventional Commitsに準拠したcommit message

## 出力

- commit hash
- commit message
- commitへ記録したpath
- commit後のstatus

## 制約

- 1回の実行で1つのcommitだけを作る。
- `git add -A`と`git commit -a`を使わない。
- `--no-verify`と`--amend`を使わない。
- 入力にないpathをstageしない。
- commit messageの1行目は`<type>[optional scope][!]: <description>`の形式とする。
- typeとscopeは英小文字とする。
- description、body、footerの説明文は日本語とする。

## 手順

### 1. Pathをstageする

```sh
git -C <repository-path> add -- <path> [<path>...]
```

### 2. Stage済みの差分を取得する

```sh
git -C <repository-path> diff --staged --check
git -C <repository-path> diff --staged --name-status
git -C <repository-path> diff --staged
```

### 3. Commitを作る

```sh
git -C <repository-path> commit -m '<message>'
```

### 4. Commitを取得する

```sh
git -C <repository-path> show --format=fuller --stat HEAD
git -C <repository-path> status --porcelain=v1 --branch
```

### 5. 結果を返す

commit hash、message、記録したpath、commit後のstatusを返す。

[^git-commit]: [Git `commit` manual](https://git-scm.com/docs/git-commit)、[Conventional Commits 1.0.0](https://www.conventionalcommits.org/ja/v1.0.0/)
