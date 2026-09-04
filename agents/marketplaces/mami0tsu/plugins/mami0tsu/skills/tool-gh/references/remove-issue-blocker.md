# remove-issue-blocker

## 情報源

- 公式ドキュメント：[GitHub CLI `gh issue edit` manual](https://cli.github.com/manual/gh_issue_edit)
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- 確認コマンド：`gh --version`、`gh issue edit --help`

## 目的

Issueから明示的に承認された1つの`blockedBy`関係を削除する。

## 前提条件

- `owner/repo`形式のrepository名
- blocked側のIssue
- 削除対象となるblocker側のIssue

## 推奨コマンド

```sh
gh issue edit <blocked-number-or-url> --repo <owner>/<repo> \
  --remove-blocked-by <blocker-number-or-url>
```

## 結果の確認

blocked側のIssueを`read-issue`ユースケースで再取得し、対象が`blockedBy`にないことを確認する。

## 停止条件

現在の関係が承認対象と一致しない場合は削除しない。

## 代表的な失敗

関係がすでに存在しない場合は再実行せず、差分が解消済みであることを返す。
