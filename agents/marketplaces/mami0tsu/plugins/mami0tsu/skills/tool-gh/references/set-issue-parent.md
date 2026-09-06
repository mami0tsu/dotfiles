# set-issue-parent

## 情報源

- 公式ドキュメント：[GitHub CLI `gh issue edit` manual](https://cli.github.com/manual/gh_issue_edit)
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- 確認コマンド：`gh --version`、`gh issue edit --help`

## 目的

1つのIssueへ承認済みの親Issueを設定する。

## 前提条件

- `host/owner/repo`で特定した同じrepositoryにある子Issueと親Issueの正の整数番号
- 現在の親子関係

## 推奨コマンド

```sh
gh issue edit <child-number> --repo <host>/<owner>/<repo> \
  --parent <parent-number>
```

## 結果の確認

子Issueを`read-issue`ユースケースで再取得し、`parent`が指定したIssueを示すことを確認する。

## 停止条件

別の親Issueが設定済みの場合は、削除または置換の承認を受けるまで停止する。

## 代表的な失敗

親子関係を利用できないrepositoryでは、providerの機能を有効化できるか人間へ確認する。
