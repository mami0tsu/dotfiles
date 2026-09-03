# list-workflow-runs

指定したbranchのworkflow runを取得する[^gh-run-list]。

## 入力

- `owner/repo`形式のrepository名
- branch
- 取得件数

## 出力

- workflow runの一覧

## 制約

- workflow runを変更しない。
- branchと取得件数を省略しない。

## 手順

### 1. Workflow runを取得する

```sh
gh run list --repo <owner>/<repo> --branch <branch> --limit <count> \
  --json databaseId,workflowName,status,conclusion,headSha,createdAt,url
```

### 2. 結果を返す

取得したJSONを返す。

[^gh-run-list]: [GitHub CLI `gh run list` manual](https://cli.github.com/manual/gh_run_list)
