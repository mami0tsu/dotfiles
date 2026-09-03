---
name: step-produce-change
description: >-
  実装準備結果に従ってコードまたは文書を変更し、必要な確認を通したcommitを作るStep。
  作業場所と実装内容が決まった後に使う。
allowed-tools: >-
  Skill(mami0tsu:task-apply-specification)
  Skill(mami0tsu:task-commit-changes)
  Skill(mami0tsu:task-run-verification)
---

# step-produce-change

実装準備結果に従ってファイルを変更し、commit済みの変更を作る。
IssueまたはDocumentに書かれていない判断が必要になった場合は、実装を止めて確認を求める。

## 入力

- 実装準備結果
- 修正指摘（再実行時）
- 直前のcommit済みの変更（再実行時）

## 出力

- commit済みの変更

## 制約

- 入力と現在のbranchやworktreeが一致しない場合は停止する。
- IssueまたはDocumentの範囲を超える変更が必要な場合は停止し、必要な判断を返す。
- 参照するスキルが利用できない場合は、そのスキル名を含む`missing-task`を返し、操作を代行しない。

## 手順

### 1. 作業状態を確認する

実装準備結果と現在のbranch、worktreeを比較する。
一致しない場合は呼び出し元へ返し、`step-prepare-implementation`スキルからやり直す。

### 2. 仕様を実装する

`task-apply-specification`スキルへ実装準備結果と修正指摘を渡し、必要なコード、test、文書を変更する。

### 3. 基本的な確認を行う

`task-run-verification`スキルを使い、IssueまたはDocumentとリポジトリで指定されたtest、lint、buildを実行する。

### 4. 変更をCommitする

`task-commit-changes`スキルへ変更結果、確認結果、直前のcommit済みの変更を渡し、意図した変更をcommitする。

### 5. Commit済みの変更を返す

実装準備結果、修正指摘、これまでに作成したcommit、最後に作成した対象commit、確認結果を、commit済みの変更として返す。
