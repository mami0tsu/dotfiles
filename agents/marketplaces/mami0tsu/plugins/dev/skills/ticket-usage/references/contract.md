# Ticket contract

provider adapter は、次の形へ ticket を正規化する。

```json
{
  "provider": "example",
  "id": "EX-123",
  "url": "https://tickets.example.invalid/tickets/EX-123",
  "title": "架空の ticket adapter を作成する",
  "description": "Markdown",
  "assignee": {
    "id": "user-id",
    "name": "display name"
  },
  "status": {
    "name": "In Progress",
    "type": "started"
  },
  "parent": {
    "id": "EX-100"
  },
  "blockedBy": [
    {"id": "EX-122"}
  ],
  "blocks": [
    {"id": "EX-124"}
  ]
}
```

`provider`、`id`、`url`、`title`、`status`は必須である。
`id`は adapter が後続の provider API 入力へ使える識別子とし、provider 内部の database UUID であることは要求しない。
provider が値を持たない optional field は `null`または空配列にする。
取得を試みていない field を、値がないものとして返さない。

## 操作

adapter は次の操作を提供する。

- **get**：正本 ID または正本 URL から一件を取得する。
- **list-children**：親 ID を指定し、直下の ticket を列挙する。
- **create**：team、title、description、assignee、state、parent、blockedBy、blocks を指定し、一回の provider 書き込みで一件作成する。
- **update**：取得済み ID を指定し、明示された field だけを更新する。
- **set-relations**：parent、blockedBy、blocks を期待する集合へ一致させる。

作成と更新は、成功した API response だけで完了としない。
`get`で再取得し、正規化した結果を期待値と比較する。

## relation の意味

`parent`は作業範囲の包含を表す。
`blockedBy`と`blocks`は実行順序を表す。
親子関係から block 関係を推測せず、block 関係から親子関係も推測しない。

`set-relations`は現在集合と期待集合の差分だけを更新する。
期待集合にない relation を削除する場合は、呼び出し元の承認範囲に削除が含まれることを確認する。

provider が条件付き更新を提供しない場合、読み取りと書き込みの間に他者の変更が入る可能性は残る。
削除を含む relation 差分は、直前に取得した集合を呼び出し元へ示し、承認済み集合と一致する場合だけ適用する。
書き込み後の集合が期待値と異なる場合は `partial-write`として停止する。

## 失敗の分類

- **not-found**：正本 ID または URL に対応する ticket がない。
- **ambiguous**：検索結果を一件へ確定できない。
- **unsupported-provider**：routing が未実装 provider を指す。
- **unsupported-relation**：provider が要求された relation を表現できない。
- **stale-ticket**：再取得した現在値が呼び出し元の期待と異なる。
- **partial-write**：API の一部だけが成功し、再取得結果が期待値と異なる。

`partial-write`では自動 rollback を試みない。
取得した現在値と成功した操作を報告し、人間の判断を待つ。
