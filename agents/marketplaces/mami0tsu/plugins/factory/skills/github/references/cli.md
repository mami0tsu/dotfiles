# コメントとレビューの補完

connector に必要な操作や版情報がない場合だけ使う。
`gh-usage` の認証・repository 確認に従い、CLI 認証がなければ保留する。
この手順は Issue/PR のトップレベルコメントとレビューの取得に限定する。

`<owner>/<repo>`、番号、ID、host は解決済み参照から指定する。
以下は github.com の例であり、別 host では `--hostname` を明示する。
`comment.json` は本文と key を含む `{"body":"..."}` 形式の JSON ファイルとする。

```sh
gh api --method GET repos/<owner>/<repo>/issues/<number>/comments --paginate
gh api --method POST repos/<owner>/<repo>/issues/<number>/comments --input /absolute/path/comment.json
gh api --method GET repos/<owner>/<repo>/issues/comments/<comment-id>
gh api --method PATCH repos/<owner>/<repo>/issues/comments/<comment-id> --input /absolute/path/comment.json
gh api --method GET repos/<owner>/<repo>/pulls/<number>/reviews --paginate
```

コメントは `id`、`html_url`、`updated_at`、`body` を照合する。
更新先が対象の Issue/PR に属し、自分が編集できるコメントであることも確認する。
レビューでは `user`、`state`、`html_url`、`submitted_at`、`commit_id` を照合する。
人間として確認された判断者の最新レビューを評価し、`DISMISSED`、`CHANGES_REQUESTED`、対象外の版を承認として扱わない。
正規化された connector 結果にこれらがなければ、値を補って成功としない。

構文は `gh 2.46.0` の `gh api --help` と以下の公式資料で確認した。
認証失敗や取得範囲不足では書き込みを続けず、結果が不明なら再投稿前に照合する。

- [Issue/PR コメント](https://docs.github.com/en/rest/issues/comments)
- [PR レビュー](https://docs.github.com/en/rest/pulls/reviews#list-reviews-for-a-pull-request)
- [gh api](https://cli.github.com/manual/gh_api)
