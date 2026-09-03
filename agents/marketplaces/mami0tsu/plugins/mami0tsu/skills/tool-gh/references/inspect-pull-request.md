# inspect-pull-request

指定したpull requestを取得する[^gh-pr-view]。

## 入力

- `owner/repo`形式のrepository名
- pull request番号またはURL

## 出力

- number
- state
- Draft状態
- base branch
- head branch
- head commit
- commit
- review状態
- merge状態
- 変更規模
- 変更済みfile
- check状態
- title
- body
- URL

## 制約

- pull requestを変更しない。
- pull request番号またはURLとrepositoryを省略しない。

## 手順

### 1. Pull requestを取得する

```sh
gh pr view <number-or-url> --repo <owner>/<repo> \
  --json number,state,isDraft,author,baseRefName,headRefName,headRefOid,commits,title,body,reviewDecision,mergeStateStatus,changedFiles,additions,deletions,files,statusCheckRollup,url
```

### 2. 結果を返す

取得したJSONを返す。

[^gh-pr-view]: [GitHub CLI `gh pr view` manual](https://cli.github.com/manual/gh_pr_view)
