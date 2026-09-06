# read-issue

## 情報源

- 公式ドキュメント：[GitHub CLI `gh issue view` manual](https://cli.github.com/manual/gh_issue_view)
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- 確認コマンド：`gh --version`、`gh issue view --help`

## 目的

Issueの内容、親子関係、依存関係、状態をJSONで取得する。

## 前提条件

- `host/owner/repo`形式のrepository名
- Issue番号またはURL

## 推奨コマンド

```sh
gh issue view <number-or-url> --repo <host>/<owner>/<repo> \
  --json number,state,stateReason,title,body,assignees,labels,parent,subIssues,blockedBy,blocking,url,updatedAt
```

## 結果の確認

返された`number`と`url`が入力対象を示すことを確認する。
後続操作で使う正本IDには、正の整数である`number`を採用する。

## 停止条件

repositoryまたはIssueを1つに特定できない場合は停止する。

## 代表的な失敗

取得権限がない場合は認証状態とrepositoryへのアクセス権を確認する。
JSON fieldが未対応の場合は`gh issue view --help`だけを確認する。
