---
name: task-request-diff-review
description: >-
  commit済みの変更を人間へ提示し、push前のレビューコメントを取得するTask。
  自動確認と差分レビューが完了した変更について、人間の判断を受け取るときに使う。
allowed-tools: >-
  Skill
---

# task-request-diff-review

commit済みの差分を人間が確認できる状態にし、レビューコメントを受け取る。
人間のコメントを解釈してファイルやcommitを変更しない。

## 入力

- commit済みの変更

## 出力

- 人間レビュー結果

## 制約

- 入力で指定されたbase commitと対象commitの差分だけを表示する。
- 対象commitが現在のbranchの最新commitでない場合は停止する。
- commitしていない変更が残っている場合は停止する。
- コード、test、文書、commitを変更しない。
- 人間のレビューが完了するまで成功として扱わない。

## 手順

### 1. レビュー対象を確認する

commit済みの変更からrepository、base commit、対象commit、worktreeを確認する。
対象commitが現在のbranchの最新commitと一致し、commitしていない変更がないことを確認する。

### 2. 人間へレビューを依頼する

base commitと対象commitの差分を人間へ提示する。

### 3. 人間レビュー結果を返す

repository、base commit、対象commit、レビューの完了状態、レビューコメントを人間レビュー結果として返す。
コメントがない場合は、修正を求めるコメントがなかったことを明示する。
