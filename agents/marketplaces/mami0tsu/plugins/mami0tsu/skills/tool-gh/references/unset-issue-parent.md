# unset-issue-parent

## 情報源

- 公式ドキュメント：[GitHub CLI `gh issue edit` manual](https://cli.github.com/manual/gh_issue_edit)
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- 確認コマンド：`gh --version`、`gh issue edit --help`

## 目的

1つのIssueから明示的に承認された親関係を外す。

## 前提条件

- `host/owner/repo`形式のrepository名
- 親を持つ子Issueの正の整数番号
- 削除対象の承認

## 推奨コマンド

```sh
gh issue edit <child-number> --repo <host>/<owner>/<repo> --remove-parent
```

## 結果の確認

子Issueを`read-issue`ユースケースで再取得し、`parent`が空であることを確認する。

## 停止条件

現在の親Issueが承認対象と一致しない場合は削除しない。

## 代表的な失敗

すでに親がない場合は再実行せず、差分が解消済みであることを返す。
