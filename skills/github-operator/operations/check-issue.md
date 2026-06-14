# check-issue

Issue を実装の参考情報として読む。

## 前提

- URL または明示番号がある Issue だけ読む
- 推測検索で対象 Issue を決めない
- 読み取り、要約、分類だけ行う
- Issue 作成、コメント、close、label 変更は行わない

## 手順

1. `common/context.md`、`common/safety.md`、`common/mcp-cli-policy.md` を読む。
2. `gh auth status` を確認する。失敗した場合は中止し、認証を依頼する。
3. repository と Issue 番号を解決する。
4. `gh issue view <issue> --comments --json ...` で Issue 本文と comments を取得する。
5. `gh issue view` で取得できない場合だけ MCP fallback を使い、fallback した理由を結果に明記する。
6. 実装メモ形式で整理する。

## 出力

```markdown
## 要件

## 制約

## 未決事項

## 参考リンク
```

不明点や矛盾がある場合は `未決事項` に明記する。
