# check-issue

Issue を実装の参考情報として読む。

## 前提

- URL または明示番号がある Issue だけ読む
- 推測検索で対象 Issue を決めない
- 読み取り、要約、分類だけ行う
- Issue 作成、コメント、close、label 変更は行わない

## 手順

1. `common/context.md`、`common/safety.md`、`common/mcp-cli-policy.md` を読む。
2. repository と Issue 番号を解決する。
3. MCP で Issue 本文と comments を取得する。
4. 実装メモ形式で整理する。

## 出力

```markdown
## 要件

## 制約

## 未決事項

## 参考リンク
```

不明点や矛盾がある場合は `未決事項` に明記する。
