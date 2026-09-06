# read-file-at-commit

## 情報源

- 公式ドキュメント：[REST API endpoints for repository contents](https://docs.github.com/en/rest/repos/contents#get-repository-content)
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- 確認コマンド：`gh --version`、`gh api --help`

## 目的

認証済みGitHub APIから、完全なcommit OIDにある1つのfile本文を取得する。

## 前提条件

- `owner/repo`形式のrepository名
- GitHub host
- 完全なcommit OID
- repository rootからのfile path

## 推奨コマンド

```sh
gh api --hostname '<host>' --method GET \
  -H 'Accept: application/vnd.github.raw+json' \
  'repos/<owner>/<repo>/contents/<percent-encoded-path>' \
  -f ref='<full-commit-oid>'
```

## 結果の確認

応答本文だけを正本本文として返す。
Host、repository、完全なcommit OID、pathが入力と一致することを確認する。

## 停止条件

Host、repository、commit、pathのいずれかを確認できない場合は停止する。
Branch名、既定branch、別のrepositoryにある同名pathへ置き換えない。

## 代表的な失敗

`404 Not Found`ではrepository、commit、path、認証権限を確認する。
取得権限がない場合は別のcredentialへ切り替えない。
