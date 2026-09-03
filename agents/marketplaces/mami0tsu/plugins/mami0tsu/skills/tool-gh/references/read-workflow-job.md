# read-workflow-job

指定したworkflow jobの失敗logを取得する[^gh-run-view]。

## 入力

- `owner/repo`形式のrepository名
- workflow job ID

## 出力

- workflow job
- 失敗したstep
- 失敗log

## 制約

- workflow runとjobを変更しない。
- log内のtoken、credential、個人情報を出力しない。

## 手順

### 1. Jobの失敗logを取得する

```sh
gh run view --repo <owner>/<repo> --job <job-id> --log-failed
```

### 2. 結果を返す

workflow job、失敗したstep、最初の原因を示すlogを返す。

[^gh-run-view]: [GitHub CLI `gh run view` manual](https://cli.github.com/manual/gh_run_view)
