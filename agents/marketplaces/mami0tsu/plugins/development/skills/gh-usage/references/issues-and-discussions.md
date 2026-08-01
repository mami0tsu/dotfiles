# Issue と Discussion

## 情報源

- 公式ドキュメント：[gh issue view](https://cli.github.com/manual/gh_issue_view)（確認コマンド：`gh issue view --help`）
- 公式ドキュメント：[gh discussion view](https://cli.github.com/manual/gh_discussion_view)（確認コマンド：`gh discussion view --help`）
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- バージョン確認：`gh --version`

## Issue を読む

### 目的

Issue の状態、本文、担当者、label、コメントを必要な範囲だけ取得する。

### 前提条件

Issue 番号または URL を取得する。

repository が現在の directory と異なる場合は `owner/repo` を取得する。

認証状態が不明な場合は `gh auth status` で確認する。

### 推奨コマンド

状態だけを確認するときは、次を使う。

```sh
gh issue view <number-or-url> --repo <owner>/<repo> \
  --json number,title,state,labels,assignees,url
```

本文と依存関係を判断するときは、必要な field を追加する。

```sh
gh issue view <number-or-url> --repo <owner>/<repo> \
  --json number,title,body,state,author,labels,blockedBy,blocking,url
```

コメントが判断に必要なときだけ `comments` field を追加する。

```sh
gh issue view <number-or-url> --repo <owner>/<repo> \
  --json number,title,state,comments,url
```

### 結果の確認

返された `number`、`title`、`state`、`url` が要求された Issue と一致することを確認する。

依存関係を扱う場合は、`blockedBy` と `blocking` を確認する。

### 停止条件

Issue の編集、コメント、close、reopen、transfer、lock などの状態変更は実行しない。

それらを求められた場合は、必要な操作と影響範囲を利用者へ確認する。

Issue 番号だけで repository を特定できない場合は、推測せず `owner/repo` を確認する。

### 代表的な失敗

`Could not resolve to an Issue` または 404 の場合は、番号、URL、`--repo` の組み合わせを確認する。

認証エラーの場合は、`gh auth status` の対象 host と token の権限を確認する。

必要な情報が `--json` 出力にない場合は、要求に必要な field だけを追加して再実行する。

## Discussion を読む

### 目的

Discussion の本文、状態、カテゴリ、採用済み回答、必要なコメントを取得する。

### 前提条件

Discussion 番号、Discussion URL、または comment URL を取得する。

コメントを時系列で評価する場合は、取得順序と件数を決める。

### 推奨コマンド

Discussion の主要な状態を読むときは、次を使う。

```sh
gh discussion view <number-or-url> --repo <owner>/<repo> \
  --json number,title,body,state,category,author,answered,answerChosenAt,url
```

コメントを読むときは、必要な順序と件数を指定する。

```sh
gh discussion view <number-or-url> --repo <owner>/<repo> \
  --comments --order oldest --limit <count>
```

1つの comment の全 reply thread が必要な場合は、comment URL または node ID を渡す。

```sh
gh discussion view <comment-url-or-node-id> --repo <owner>/<repo> \
  --limit <count> --order oldest
```

### 結果の確認

返された `number`、`title`、`category`、`state`、`url` を確認する。

回答を扱う場合は、`answered` と `answerChosenAt` を確認する。

コメントを扱う場合は、指定した順序と件数で十分かを確認する。

### 停止条件

Discussion の作成、編集、コメント、回答の選択、close は実行しない。

Discussion は preview 機能であり、実行結果が reference と異なる場合は対象 subcommand の help を確認してから続行する。

### 代表的な失敗

コメントの一部しか得られない場合は、`--after` に返された cursor を渡して次のページを取得する。

reply が見つからない場合は、Discussion 全体ではなく comment URL または node ID を渡して取得する。

権限エラーの場合は、非公開 repository または Discussion にアクセスできる認証状態かを確認する。
