---
name: workflow-implement
description: >-
  IssueまたはDocumentを入力とし、実装準備、変更作成、検証、提案のStepを順に進めてDraft PR URLを返すWorkflow。
  IssueまたはDocumentに基づくソフトウェア変更をDraft PRまで進めるときに使う。
allowed-tools: >-
  Skill(mami0tsu:step-prepare-implementation)
  Skill(mami0tsu:step-produce-change)
  Skill(mami0tsu:step-propose-change)
  Skill(mami0tsu:step-validate-change)
---

# workflow-implement

IssueまたはDocumentを、レビュー可能なDraft PRへ変換する。
WorkflowはStepの順序と入出力の引き渡しだけを管理し、成果物の内容確認と具体的な操作は各Stepに委譲する。

## 入力

- IssueまたはDocument

## 出力

- Draft PRのURL

## 制約

- Stepを記載順に実行する。
- 前のStepの出力を次のStepの入力として渡す。
- Stepが完了しなかった場合は後続Stepを実行せず、停止理由を返す。
- Taskを直接呼び出さず、成果物の内容をWorkflowで解釈し直さない。

## 手順

### 1. 実装を準備する

`step-prepare-implementation`スキルへIssueまたはDocumentを渡し、実装準備結果を受け取る。

### 2. 変更を作る

`step-produce-change`スキルへ実装準備結果を渡し、commit済みの変更を受け取る。

### 3. 変更を検証する

`step-validate-change`スキルへcommit済みの変更を渡し、検証済みの変更を受け取る。
修正指摘が返った場合は、実装準備結果と修正指摘を`step-produce-change`スキルへ渡す。
直前のcommit済みの変更も`step-produce-change`スキルへ渡す。
新しいcommit済みの変更を受け取り、`step-validate-change`スキルからやり直す。

### 4. 変更を提案する

`step-propose-change`スキルへ検証済みの変更を渡し、Draft PR URLを受け取って返す。
