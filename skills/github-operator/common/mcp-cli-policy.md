# MCP と GitHub CLI の使い分け

基本は GitHub MCP を優先する。MCP が弱い領域、または local branch と強く結びつく解決だけ GitHub CLI を使う。

## MCP を優先する操作

- repository metadata の取得
- default branch の取得
- Draft PR 作成
- PR metadata の取得
- PR comments の軽量確認
- Issue の取得
- repository file の取得
- PR template file の取得

## GitHub CLI を使う操作

- current branch から current PR を解決する
- GitHub Actions checks を確認する
- GitHub Actions logs を取得する
- review thread の unresolved/resolved、outdated、inline location を GraphQL で取得する
- Discussion を read-only GraphQL/API で取得する

## fallback

Draft PR 作成は MCP を優先する。MCP で権限、head repo、API 制約などにより失敗した場合だけ、`gh pr create --draft` に fallback してよい。

fallback しても、書き込みは Draft PR 作成だけに限定する。
