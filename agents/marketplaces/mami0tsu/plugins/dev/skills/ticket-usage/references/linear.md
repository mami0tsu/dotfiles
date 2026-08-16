# Linear adapter

Linear MCP の issue tool を contract へ対応づける。

## 読み取り

一件の取得には `get_issue`を使い、常に `includeRelations: true`を指定する。
返された `id`を正本 ID、`url`を正本 URL とする。

URL 入力は `https://linear.app/<workspace>/issue/<identifier>/<slug>`の形だけを受理する。
`issue`直後の path segment を identifier として取り出し、percent decode や slug から ID を推測しない。
取得後は返された正本 URL も同じ規則で解析し、workspace と identifier が入力 URL と一致することを確認する。
返された `id`は後続の Linear MCP 入力に使う provider identifier とし、URL の identifier や内部 UUID との一致を要求しない。
形式が異なる URL は `ambiguous`として停止する。

子 ticket の列挙には `list_issues`の `parentId`を使う。
判断に必要な field だけを `fields`へ指定する。
pagination がある場合は cursor がなくなるまで取得する。

担当者を人間の指定から解決する場合は `get_user`を使う。
team は推測せず `get_team`で key、name、UUID のいずれかを解決する。
作成または更新で状態名を指定する前に、`list_issue_statuses`で対象 team の有効な状態を確認する。

## 作成と更新

作成と更新には `save_issue`を使う。
作成時は `team`と`title`を必須にする。
担当者には `assigneeId`ではなく `assignee`を渡す。

parent、blockedBy、blocks を持つ ticket は、それらを同じ `save_issue`へ渡して作成する。
relation を後続 call へ分割しない。

既存 ticket の更新では `id`を必ず指定する。
description の局所変更は、一意な anchor を確認できる場合だけ `patch`を使う。
一意性を確認できない場合は、取得済みの全文を元にした `description`更新を呼び出し元へ提示する。

## relation の更新

親の設定には `parentId`を使う。
親を外す場合は `parentId: null`を使う。

block relation は、現在集合と期待集合を比較して次の引数へ分ける。

- 追加する blocker：`blockedBy`
- 削除する blocker：`removeBlockedBy`
- block する ticket の追加：`blocks`
- block する ticket の削除：`removeBlocks`

同じ relation を追加と削除の両方へ入れない。
parent と block relation を一度に変更する場合は、すべての対象 ID を先に解決する。
解決できない ID が一件でもあれば `save_issue`を呼ばない。
親とすべての block 対象について、archive または cancel 済みでないことを確認する。
作成先 team と parent の組み合わせを Linear が受理するか判断できない場合も、書き込み前に停止する。

## 検証

書き込み後は `get_issue`を `includeRelations: true`で実行する。
次を contract の期待値と比較する。

- `assigneeId`
- `status`と`statusType`
- `parentId`
- `relations.blockedBy[].id`
- `relations.blocks[].id`
- `url`

relation の配列順は意味を持たないため、ID の集合として比較する。
期待値と異なる場合は `partial-write`として停止する。

## provider の制約

Linear adapter は親を一件だけ扱う。
複数の親を要求された場合は `unsupported-relation`として停止する。
親子関係と block 関係は別々に保存し、一方から他方を補完しない。

Linear の issue 更新には version または ETag による条件付き書き込みがない。
書き込み直前の再取得と書き込み後の検証は競合を検出しやすくするが、競合の発生そのものは防げない。
