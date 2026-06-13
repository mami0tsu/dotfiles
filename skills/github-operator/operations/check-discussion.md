# check-discussion

Discussion を実装の参考情報として読む。

## 前提

- URL または明示番号がある Discussion だけ読む
- 推測検索で対象 Discussion を決めない
- 読み取り、要約、分類だけ行う
- Discussion 作成、コメント、close は行わない
- MCP に Discussion 取得機能がない場合は、`gh api` または `gh api graphql` の read-only 取得を使う

## 手順

1. `common/context.md`、`common/safety.md`、`common/mcp-cli-policy.md` を読む。
2. repository と Discussion 番号を解決する。
3. MCP で取得できる場合は MCP を優先する。
4. MCP で取得できない場合は `gh` の read-only GraphQL/API で取得する。
5. 実装メモ形式で整理する。

## 出力

```markdown
## 要件

## 制約

## 未決事項

## 参考リンク
```

Discussion 内で結論が出ていない内容は `未決事項` に分ける。
