# find-issues

## 情報源

- 公式ドキュメント：[GitHub CLI `gh issue list` manual](https://cli.github.com/manual/gh_issue_list)
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- 確認コマンド：`gh --version`、`gh issue list --help`

## 目的

Issue作成結果が曖昧な場合に、同じ作成操作を繰り返さず候補を列挙する。

## 前提条件

- `owner/repo`形式のrepository名
- 承認済みtitle

## 推奨コマンド

```sh
gh issue list --repo <owner>/<repo> --state all --limit 20 \
  --search 'in:title "<title>" sort:created-desc' \
  --json number,state,title,url,createdAt,updatedAt
```

## 結果の確認

title、作成時刻、URLを比較し、一意に確定できない候補をすべて人間へ提示する。

## 停止条件

候補がない場合や複数残る場合は、Issueを自動選択しない。

## 代表的な失敗

検索構文が未対応の場合は`gh issue list --help`だけを確認する。
結果が上限へ達した場合は条件を狭めるための入力を人間へ求める。
