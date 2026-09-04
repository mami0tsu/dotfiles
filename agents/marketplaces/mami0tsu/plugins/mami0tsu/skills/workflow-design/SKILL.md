---
name: workflow-design
description: >-
  生の要求、Issue、Documentを入力とし、設計の作成、検証、公開を進め、着手可能な実装Issueを返すWorkflow。
  Issue、Wiki、Git管理Documentのいずれかを設計の正本として、ソフトウェア変更を設計するときに使う。
allowed-tools: >-
  Skill(mami0tsu:step-prepare-design)
  Skill(mami0tsu:step-produce-design)
  Skill(mami0tsu:step-publish-design)
  Skill(mami0tsu:step-validate-design)
---

# workflow-design

要求を、公開済みの設計正本と着手可能な実装Issueへ変換する。
WorkflowはStepの順序と成果物の引き渡しだけを管理し、設計内容や外部操作を解釈し直さない。

## 入力

- 生の要求、Issue、またはDocument
- Workflow ID（再開時）

## 出力

- 設計引き渡し結果

## 制約

- Stepを記載順に実行する。
- 前のStepの出力を次のStepへそのまま渡す。
- Stepが停止した場合は後続Stepを実行せず、停止理由と再開に必要な入力を返す。
- TaskやToolを直接呼び出さない。
- 外部Objectを作成、更新、関係設定、削除しない。

## 手順

### 1. 設計を準備する

`step-prepare-design`スキルへ入力を渡し、設計準備結果を受け取る。

### 2. 設計を作る

`step-produce-design`スキルへ設計準備結果を渡し、設計成果物を受け取る。

### 3. 設計を検証する

`step-validate-design`スキルへ設計成果物を渡し、承認済み設計を受け取る。
修正指摘が返った場合は、設計準備結果、設計成果物、修正指摘を`step-produce-design`スキルへ渡し、設計の作成からやり直す。

### 4. 設計を公開する

`step-publish-design`スキルへ承認済み設計を渡す。
正本とIssueの公開結果を検証した設計引き渡し結果を受け取り、その結果を返す。
