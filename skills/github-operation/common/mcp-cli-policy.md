# GitHub CLI と MCP の使い分け

基本は GitHub CLI を優先する。MCP は、`gh auth status` が成功しているにもかかわらず、GitHub CLI の取得失敗、機能不足、API 差分などで進められない場合だけ fallback として使う。

`gh auth status` が失敗した場合は MCP fallback せずに中止する。`gh auth status` の結果を伝え、ユーザーに `gh auth login` などで認証してもらう。

## GitHub CLI を優先する操作

- repository metadata の取得: `gh repo view`
- default branch の取得: `gh repo view --json defaultBranchRef`
- Draft PR 作成: `gh pr create --draft`
- PR metadata の取得: `gh pr view`
- current PR の解決: `gh pr view --json number,url`
- Issue の取得: `gh issue view`
- current branch から current PR を解決する
- GitHub Actions checks を確認する
- GitHub Actions logs を取得する
- review thread の unresolved/resolved、outdated、inline location を GraphQL で取得する
- Discussion を read-only GraphQL/API で取得する
- repository file と PR template file を read-only API で取得する

## `gh api`

`gh api` は read-only endpoint または read-only GraphQL query に限定する。write 系 endpoint と GraphQL mutation は使わない。

## MCP fallback

読み取り操作の MCP fallback は、ユーザー確認なしで実行してよい。ただし、fallback した理由を結果に明記する。

Draft PR 作成の MCP fallback は、`gh pr create --draft` が認証以外の理由で失敗した場合だけ許可する。実行前にユーザー確認を挟む。

fallback しても、書き込みは Draft PR 作成だけに限定する。
