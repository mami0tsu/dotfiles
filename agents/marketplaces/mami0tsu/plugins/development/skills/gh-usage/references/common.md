# 共通の事前確認

## 情報源

- 公式ドキュメント：[gh auth status](https://cli.github.com/manual/gh_auth_status)（確認コマンド：`gh auth status --help`）
- 公式ドキュメント：[gh auth login](https://cli.github.com/manual/gh_auth_login)（確認コマンド：`gh auth login --help`）
- 公式ドキュメント：[gh の環境変数](https://cli.github.com/manual/gh_help_environment)（確認コマンド：`gh help environment`）
- 公式ドキュメント：[gh repo view](https://cli.github.com/manual/gh_repo_view)（確認コマンド：`gh repo view --help`）
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- バージョン確認：`gh --version`

## 認証の扱い

`github.com` では `GH_TOKEN`、`GITHUB_TOKEN`、保存済み認証の順に `gh` が認証情報を選ぶ。

この環境では `GH_TOKEN= GITHUB_TOKEN= gh auth login --hostname github.com --web` を認証の更新窓口とする。

成功した認証情報は macOS の credential store に保存される。

対話シェルの `codex` と `claude` は、`GH_TOKEN` と `GITHUB_TOKEN` を外した状態で保存済み認証を読み出す。

取得した token は起動するプロセスにだけ `GH_TOKEN` として渡す。

このため、GitHub CLI 用の token はシェルの環境変数、コマンドライン引数、履歴には残らない。

`GH_TOKEN` は Codex または Claude Code の内部で実行する `gh` の認証にも使う。

Codex の sandbox が macOS Keychain を直接参照できない場合でも、起動時に読み出した認証で `gh` の読み取りコマンドを実行できる。

`gh auth token` は token を標準出力へ出すため、手動の診断には使わない。

## 通信失敗を認証失効と区別する

`GH_TOKEN= GITHUB_TOKEN= gh auth status --hostname github.com` は保存済み認証を読むだけではなく、GitHub への通信で認証状態を検査する。

Codex の sandbox 内で DNS、TLS、接続拒否などの通信失敗が出ても、その結果だけで token が無効になったとは判断しない。

まず通常の対話シェルで `GH_TOKEN= GITHUB_TOKEN= gh auth status --hostname github.com` を実行する。

このコマンドは `GH_TOKEN` と `GITHUB_TOKEN` を外してから保存済み認証を検査するため、起動ラッパーと同じ認証を診断する。

対話シェルでも認証の失敗が再現するときだけ、`GH_TOKEN= GITHUB_TOKEN= gh auth login --hostname github.com --web` で認証を更新する。

保存済み認証の読み出しに失敗して Codex または Claude Code が起動しない場合も、同じ手順で確認する。

## 認証と対象 repository を確認する

### 目的

読み取りまたは Draft pull request 作成に使う GitHub host と repository を確定する。

### 前提条件

作業対象が現在の Git repository に属するか、`owner/repo` または URL で特定できるかを確認する。

### 推奨コマンド

親シェルで保存済み認証を確認する。

```sh
GH_TOKEN= GITHUB_TOKEN= gh auth status --hostname github.com
```

Codex または Claude Code の内部では、起動時に渡された `GH_TOKEN` を `gh` が使う。

内部の `gh auth status --hostname github.com` は、その注入済み token を確認するコマンドである。

保存済み認証を診断するときは、親シェルで上記のコマンドを実行する。

現在の directory が対象 repository に属する場合は、repository を確認する。

```sh
gh repo view --json nameWithOwner,url
```

対象が別の repository の場合は、以後のコマンドに `--repo <owner>/<repo>` を付ける。

### 結果の確認

親シェルの `GH_TOKEN= GITHUB_TOKEN= gh auth status --hostname github.com` が、保存済み認証による有効な account を示すことを確認する。

`gh repo view` の `nameWithOwner` と `url` が、要求された repository の識別子と URL に一致することを確認する。

### 停止条件

認証に失敗した場合は、token の表示や再認証を自動で実行しない。

対象 repository が複数候補に分かれる場合は、利用者へ `owner/repo` を確認する。

### 代表的な失敗

親シェルの `GH_TOKEN= GITHUB_TOKEN= gh auth status --hostname github.com` が exit code 1 を返す場合は、通信失敗と保存済み認証の失効を区別する。

`gh repo view` が current directory の repository を解決できない場合は、`--repo <owner>/<repo>` を付ける。
