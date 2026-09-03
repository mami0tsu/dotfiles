# read-checks

指定したpull requestのcheckを取得する[^gh-pr-checks]。

## 入力

- `owner/repo`形式のrepository名
- pull request番号またはURL

## 出力

- check名
- state
- bucket
- workflow
- URL

## 制約

- checkとworkflow runを変更しない。
- exit code 8をpendingとして扱う。

## 手順

### 1. Checkを取得する

```sh
gh pr checks <number-or-url> --repo <owner>/<repo> \
  --json name,state,bucket,workflow,link
```

### 2. 結果を返す

取得したJSONとexit codeを返す。

[^gh-pr-checks]: [GitHub CLI `gh pr checks` manual](https://cli.github.com/manual/gh_pr_checks)
