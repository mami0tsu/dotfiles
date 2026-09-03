# inspect-repository

指定したGitHub repositoryの名前、URL、default branchを取得する[^gh-repo-view]。

## 入力

- `owner/repo`形式のrepository名

## 出力

- `nameWithOwner`
- repositoryのURL
- default branch

## 制約

- repositoryをcurrent directoryから推測しない。
- repositoryを変更しない。

## 手順

### 1. Repositoryを取得する

```sh
gh repo view <owner>/<repo> --json nameWithOwner,url,defaultBranchRef
```

### 2. 結果を返す

`nameWithOwner`、repositoryのURL、`defaultBranchRef.name`を返す。

[^gh-repo-view]: [GitHub CLI `gh repo view` manual](https://cli.github.com/manual/gh_repo_view)
