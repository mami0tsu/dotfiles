# close-issue

## 情報源

- 公式ドキュメント：[GitHub CLI `gh issue close` manual](https://cli.github.com/manual/gh_issue_close)
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- 確認コマンド：`gh --version`、`gh issue close --help`

## 目的

完了したIssueを`completed`理由でcloseする。

## 前提条件

- `host/owner/repo`形式のrepository名
- 完了条件を満たしたIssueの正の整数番号

## 推奨コマンド

```sh
gh issue close <number> --repo <host>/<owner>/<repo> --reason completed
```

## 結果の確認

`read-issue`ユースケースで再取得し、`state`が`CLOSED`であることを確認する。

## 停止条件

完了条件またはcloseの承認を確認できない場合は実行しない。

## 代表的な失敗

すでにcloseされている場合は`stateReason`を確認し、異なる理由を上書きしない。
