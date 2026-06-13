# check-review-comments

PR のレビューコメントと未解決 thread を確認し、実装向けに分類する。

## 前提

- 分析だけ行う
- コード修正、コメント返信、thread resolve は行わない
- review thread の取得は `gh` GraphQL を必須にする
- MCP は PR metadata と patch context に使う

## 手順

1. `common/context.md`、`common/safety.md`、`common/mcp-cli-policy.md` を読む。
2. PR を解決する。
3. MCP で PR metadata と必要な patch context を取得する。
4. `gh auth status` を確認する。
5. `gh api graphql` で reviewThreads を取得する。
6. コメントを分類する。
   - 未解決 actionable
   - 質問、補足、議論
   - resolved
   - outdated
   - 重複または対応不要
7. 実装や返信は行わず、次に取るべき行動をまとめる。

## GraphQL で見る情報

- thread resolved state
- outdated state
- file path
- line / original line
- comment body
- author
- createdAt

## 出力

- 未解決 actionable comments
- 判断が必要な質問や議論
- 対応不要または stale なコメント
- 後続タスクに渡せる短い実装メモ
