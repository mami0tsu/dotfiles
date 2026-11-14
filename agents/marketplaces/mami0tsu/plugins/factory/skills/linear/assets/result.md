## Factory Linear

```text
status: success | wait | error
items: [{id, url, state, revision, commentId, key, idea, output, artifacts, parentId, blockedBy, blocks}]
reason:
remainingKeys: []
```

未取得の値は推測せず、その項目と理由を示す。
`reason` に判断の根拠または不足項目と停止理由を記し、`remainingKeys` に未完了の key を列挙する。
成果物の版を確認できない場合と書き込み結果が不明な場合は `wait` を返す。
