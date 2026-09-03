---
name: step-validate-change
description: >-
  commit済みの変更を自動確認、差分レビュー、人間レビューへ通し、修正が必要な指摘を見つけるStep。
  pushしてDraft PRを作る前に使う。
allowed-tools: >-
  Skill(mami0tsu:task-request-diff-review)
  Skill(mami0tsu:task-review-diff)
  Skill(mami0tsu:task-run-verification)
---

# step-validate-change

commit済みの変更が要求を満たし、既存の動作を壊していないか確認する。
修正が必要な場合は変更作業へ戻し、修正後のcommitをもう一度確認する。

## 入力

- commit済みの変更

## 出力

- 検証済みの変更または修正指摘

## 制約

- 入力のcommitが現在のbranchにない場合、またはcommitしていない変更が残っている場合は停止する。
- 修正が必要な指摘を残したまま完了しない。
- 参照するスキルが利用できない場合は、そのスキル名を含む`missing-task`を返し、操作を代行しない。

## 手順

### 1. 変更を確認する

入力のcommitと現在のbranch、worktreeを比較する。
commit済みの変更に、実装準備結果、起点commit、対象commit、確認方法が含まれていることを確認する。

### 2. Testを実行する

`task-run-verification`スキルを使い、IssueまたはDocumentとリポジトリで指定されたtest、lint、buildを実行する。

### 3. 差分をレビューする

`task-review-diff`スキルを使い、要求とのずれ、既存機能への影響、test不足を確認する。

### 4. 指摘を返す

差分レビューで修正が必要な問題を見つけた場合は、問題箇所、影響、修正内容、確認方法を修正指摘として返す。

### 5. 人間へレビューを依頼する

`task-request-diff-review`スキルを使い、起点commitと対象commitの差分を人間へ提示する。

### 6. 人間の指摘を返す

人間レビューでコメントが返った場合は、コメントの場所、内容、対象commitを修正指摘として返す。

### 7. 検証済みの変更を返す

commit済みの変更、検証時の確認結果、差分レビュー結果、人間レビュー結果を検証済みの変更として返す。
