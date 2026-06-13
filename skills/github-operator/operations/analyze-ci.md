# analyze-ci

PR の現在失敗している CI checks を分析する。待機はしない。

## 前提

- 現在失敗している checks だけを対象にする
- in progress は待たず、未完了として報告する
- GitHub Actions logs は `gh` を使う
- 外部 CI は状態と URL の報告までに留める
- 実装修正は行わない

## 手順

1. `common/context.md`、`common/safety.md`、`common/mcp-cli-policy.md` を読む。
2. PR を解決する。
3. PR metadata は MCP で取得する。
4. `gh auth status` を確認する。
5. `gh pr checks` で checks を取得する。
6. 失敗中の GitHub Actions check だけ logs を取得する。
7. in progress、skipped、success、外部 CI は分類して報告する。
8. 原因、該当ログ、推奨対応をまとめる。

## コマンド

```sh
gh pr checks <pr> --json name,state,bucket,link,startedAt,completedAt,workflow
gh run view <run-id> --json name,workflowName,conclusion,status,url,event,headBranch,headSha
gh run view <run-id> --log
```

必要な場合だけ read-only endpoint へ `gh api` を使う。

```sh
gh api "/repos/<owner>/<repo>/actions/jobs/<job-id>/logs"
```

## 出力

- failing check name
- run URL
- 失敗箇所の短い log snippet
- 推定原因
- 推奨対応
- 未完了 checks と外部 CI の扱い
