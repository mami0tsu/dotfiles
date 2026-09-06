# reopen-issue

## 情報源

- 公式ドキュメント：[GitHub CLI `gh issue reopen` manual](https://cli.github.com/manual/gh_issue_reopen)
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- 確認コマンド：`gh --version`、`gh issue reopen --help`

## 目的

承認済みの状態変更として、closeされたIssueをopenへ戻す。

## 前提条件

- `host/owner/repo`形式のrepository名
- closeされたIssue
- reopenの承認

## 推奨コマンド

```sh
gh issue reopen <number-or-url> --repo <host>/<owner>/<repo>
```

## 結果の確認

`read-issue`ユースケースで再取得し、`state`が`OPEN`であることを確認する。

## 停止条件

意味上の状態が未着手または進行中へ変わる根拠がない場合は実行しない。

## 代表的な失敗

すでにopenの場合は再実行せず、期待状態と一致すると判断する。
