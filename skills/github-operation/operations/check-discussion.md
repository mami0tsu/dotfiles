# check-discussion

Discussion を実装の参考情報として読む。

## 前提

- URL または明示番号がある Discussion だけ読む
- 推測検索で対象 Discussion を決めない
- 読み取り、要約、分類だけ行う
- Discussion 作成、コメント、close は行わない
- `gh api` または `gh api graphql` の read-only 取得を使う

## 手順

1. `common/context.md`、`common/safety.md`、`common/mcp-cli-policy.md` を読む。
2. `gh auth status` を確認する。失敗した場合は中止し、認証を依頼する。
3. repository と Discussion 番号を解決する。
4. `gh` の read-only GraphQL/API で取得する。
5. `gh` で取得できない場合だけ MCP fallback を使い、fallback した理由を結果に明記する。
6. 実装メモ形式で整理する。

## 出力

```markdown
## 要件

## 制約

## 未決事項

## 参考リンク
```

Discussion 内で結論が出ていない内容は `未決事項` に分ける。
