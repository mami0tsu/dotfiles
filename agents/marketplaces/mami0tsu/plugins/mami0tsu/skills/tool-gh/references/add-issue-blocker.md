# add-issue-blocker

## 情報源

- 公式ドキュメント：[GitHub CLI `gh issue edit` manual](https://cli.github.com/manual/gh_issue_edit)
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- 確認コマンド：`gh --version`、`gh issue edit --help`

## 目的

実装順序を表すため、Issueへ1つの`blockedBy`関係を追加する。

## 前提条件

- `owner/repo`形式のrepository名
- blocked側のIssue
- blocker側のIssue

## 推奨コマンド

```sh
gh issue edit <blocked-number-or-url> --repo <owner>/<repo> \
  --add-blocked-by <blocker-number-or-url>
```

## 結果の確認

blocked側のIssueを`read-issue`ユースケースで再取得し、`blockedBy`に指定したIssueがあることを確認する。

## 停止条件

対象Issueの方向を一意に判断できない場合は関係を追加しない。

## 代表的な失敗

関係がすでに存在する場合は再追加せず、期待状態と一致すると判断する。
