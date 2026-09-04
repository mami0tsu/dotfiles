---
name: step-prepare-design
description: >-
  要求を読み、Issue構成、設計正本、対象リポジトリ、承認単位を決め、追跡用Issueと再開状態を準備するStep。
  ソフトウェア変更の設計を始める前、または保存済みの設計工程を再開するときに使う。
allowed-tools: >-
  Skill(mami0tsu:task-create-issue)
  Skill(mami0tsu:task-initialize-state)
  Skill(mami0tsu:task-inspect-repository)
  Skill(mami0tsu:task-plan-design-work)
  Skill(mami0tsu:task-read-issue)
  Skill(mami0tsu:task-read-requirements)
  Skill(mami0tsu:task-request-artifact-approval)
  Skill(mami0tsu:task-update-state)
  Skill(mami0tsu:task-verify-issue)
  Skill(mami0tsu:task-verify-state)
---

# step-prepare-design

設計に必要な入力と外部Objectを確定し、中断後も同じ作業を再開できる状態を作る。
利用者がIssue構成と正本を選ぶまで、外部Objectを変更しない。

## 入力

- 生の要求、Issue、またはDocument
- Workflow ID（再開時）

## 出力

- 設計準備結果

## 制約

- `standalone-issue`と`tracking-issue`を自動選択しない。
- Issue、Wiki、Git管理Documentのいずれを正本にするか人間に選んでもらう。
- 1つの工程に属するIssueは、同じproviderとcontainerへ置く。
- 複数リポジトリでも設計Issueと正本は1つにする。
- 外部書き込み前に、対象成果物の承認とpending operationの記録を完了する。
- 作成結果が曖昧な操作を再実行しない。

## 手順

### 1. 要求を読む

既存Issueが入力に含まれる場合は、先に`task-read-issue`スキルで現在状態と正本URLを取得する。
`task-read-requirements`スキルへ生の要求、Issue読取結果、またはDocumentを渡し、要求の読み取り結果を受け取る。

### 2. 設計作業を計画する

`task-plan-design-work`スキルへ要求の読み取り結果と既存Issueを渡す。
Issue構成、provider、container、正本、基準リポジトリ、対象リポジトリ、承認予定を含む設計作業計画を受け取る。

### 3. 状態を準備する

Workflow IDがない場合は`task-initialize-state`スキルを使い、基準リポジトリへ状態を作る。
Workflow IDがある場合は`task-verify-state`スキルを使い、保存済みidentityと設計作業計画を照合する。

### 4. 追跡用Issueを準備する

既存Issueを使わない場合は、作成する`standalone-issue`または`tracking-issue`を`task-request-artifact-approval`スキルへ渡す。
承認とpending operationを記録した後、`task-create-issue`スキルで一件作成し、`task-verify-issue`スキルで確認する。
`tracking-issue`では同じ手順で設計Issueを一件作り、親子関係を後続Stepへ引き渡す。

### 5. リポジトリを調べる

対象リポジトリごとに`task-inspect-repository`スキルを実行する。
各結果を対象リポジトリに対応付け、別のリポジトリの事実を混ぜない。

### 6. 準備結果を返す

要求の読み取り結果、設計作業計画、Workflow ID、追跡用Issue、対象リポジトリごとの調査結果を設計準備結果として返す。
`task-update-state`スキルで外部Objectの識別情報と完了した操作を記録する。
