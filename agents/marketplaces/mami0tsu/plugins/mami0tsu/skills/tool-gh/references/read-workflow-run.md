# read-workflow-run

指定したworkflow runのjobと失敗logを取得する[^gh-run-view]。

## 入力

- `owner/repo`形式のrepository名
- workflow run ID

## 出力

- workflow run
- job
- 失敗したstep
- 失敗log

## 制約

- workflow runを変更しない。
- log内のtoken、credential、個人情報を出力しない。

## 手順

### 1. Workflow runを取得する

```sh
gh run view <run-id> --repo <owner>/<repo> \
  --json databaseId,workflowName,status,conclusion,jobs,url
```

### 2. 失敗logを取得する

```sh
gh run view <run-id> --repo <owner>/<repo> --log-failed
```

### 3. 結果を返す

workflow run、job、失敗したstep、最初の原因を示すlogを返す。

[^gh-run-view]: [GitHub CLI `gh run view` manual](https://cli.github.com/manual/gh_run_view)
