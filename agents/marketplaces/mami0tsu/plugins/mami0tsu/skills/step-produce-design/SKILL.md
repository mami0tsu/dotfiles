---
name: step-produce-design
description: >-
  設計準備結果から要求を明確にし、設計本文と一PR単位の実装Issue計画を作るStep。
  設計対象と保存先を確定した後、公開前の設計成果物を作るときに使う。
allowed-tools: >-
  Skill(mami0tsu:task-clarify-requirements)
  Skill(mami0tsu:task-draft-design)
  Skill(mami0tsu:task-plan-implementation)
  Skill(mami0tsu:task-update-state)
---

# step-produce-design

要求とリポジトリの事実から、設計本文と実装Issue計画を作る。
設計本文と実装境界が食い違う場合は、どちらかを推測で確定せず作成を反復する。

## 入力

- 設計準備結果
- 直前の設計成果物（再実行時）
- 修正指摘（再実行時）

## 出力

- 設計成果物

## 制約

- リポジトリから確認できる事実を人間へ質問しない。
- 未決事項、矛盾、根拠のない実装境界を残したまま完了しない。
- 1つの実装Issueを、1つのリポジトリと、実装時に作る1つのbranch、worktree、PRへ対応させる。
- branchとbase branchを設計時に固定しない。
- 設計の正本やIssueを変更しない。

## 手順

### 1. 要求を明確にする

`task-clarify-requirements`スキルへ設計準備結果、直前の設計成果物、修正指摘を渡す。
決定事項、未決事項、根拠を含む要求確認結果を受け取る。

### 2. 設計本文を作る

未決事項がなくなった後、`task-draft-design`スキルへ要求確認結果とリポジトリ調査結果を渡す。

### 3. 実装を計画する

`task-plan-implementation`スキルへ設計本文と設計作業計画を渡し、実装Issue計画を受け取る。

### 4. 整合性を確認する

要求、設計判断、受け入れ条件、実装Issueが対応し、すべての変更範囲が一件の実装Issueに属することを確認する。
矛盾または未割り当ての範囲がある場合は、要求の明確化または設計本文の作成へ戻る。

### 5. 設計成果物を返す

設計準備結果、要求確認結果、設計本文、実装Issue計画、未決事項を設計成果物として返す。
`task-update-state`スキルで成果物のdigestと完了した操作を記録する。
