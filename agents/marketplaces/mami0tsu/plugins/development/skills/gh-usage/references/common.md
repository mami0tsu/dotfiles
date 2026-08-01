# 共通の事前確認

## 情報源

- 公式ドキュメント：[gh auth status](https://cli.github.com/manual/gh_auth_status)（確認コマンド：`gh auth status --help`）
- 公式ドキュメント：[gh repo view](https://cli.github.com/manual/gh_repo_view)（確認コマンド：`gh repo view --help`）
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- バージョン確認：`gh --version`

## 認証と対象 repository を確認する

### 目的

読み取りまたは Draft pull request 作成に使う GitHub host と repository を確定する。

### 前提条件

作業対象が現在の Git repository に属するか、`owner/repo` または URL で特定できるかを確認する。

### 推奨コマンド

認証状態を確認する。

```sh
gh auth status
```

現在の directory が対象 repository に属する場合は、repository を確認する。

```sh
gh repo view --json nameWithOwner,url
```

対象が別の repository の場合は、以後のコマンドに `--repo <owner>/<repo>` を付ける。

### 結果の確認

`gh auth status` が対象 host の有効な account を示すことを確認する。

`gh repo view` の `nameWithOwner` と `url` が、要求された repository の識別子と URL に一致することを確認する。

### 停止条件

認証に失敗した場合は、token の表示や再認証を自動で実行しない。

対象 repository が複数候補に分かれる場合は、利用者へ `owner/repo` を確認する。

### 代表的な失敗

`gh auth status` が exit code 1 を返す場合は、対象 host の認証状態または token の期限を確認する。

`gh repo view` が current directory の repository を解決できない場合は、`--repo <owner>/<repo>` を付ける。
