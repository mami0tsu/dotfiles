# find-pull-request

指定したhead branchを使うpull requestを検索する[^gh-pr-list]。

## 入力

- `owner/repo`形式のrepository名
- head branch

## 出力

- pull requestの検索結果

## 制約

- head branchを省略しない。
- pull requestを変更しない。

## 手順

### 1. Pull requestを検索する

```sh
gh pr list --repo <owner>/<repo> --head <head-branch> --state all \
  --json number,state,isDraft,baseRefName,headRefName,title,url
```

### 2. 結果を返す

取得したJSONを返す。

[^gh-pr-list]: [GitHub CLI `gh pr list` manual](https://cli.github.com/manual/gh_pr_list)
