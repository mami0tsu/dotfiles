# create-issue

## 情報源

- 公式ドキュメント：[GitHub CLI `gh issue create` manual](https://cli.github.com/manual/gh_issue_create)
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- 確認コマンド：`gh --version`、`gh issue create --help`

## 目的

承認済みのtitleと本文からIssueを一件作る。

## 前提条件

- `owner/repo`形式のrepository名
- title
- 権限`0600`のbody file

## 推奨コマンド

```sh
gh issue create --repo <owner>/<repo> \
  --title '<title>' --body-file <body-file>
```

## 結果の確認

出力されたURLを`read-issue`ユースケースで取得し、titleと本文を照合する。

## 停止条件

同じ作成操作の結果が不明な場合は再実行せず、`find-issues`ユースケースで候補Issueを人間へ提示する。

## 代表的な失敗

作成権限がない場合は認証状態とrepositoryの権限を確認する。
body fileを読めない場合は権限とpathを確認し、本文をcommand lineへ展開しない。
