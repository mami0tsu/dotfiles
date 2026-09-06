---
name: step-propose-change
description: >-
  検証済みの変更をpushし、入力のIssueまたはDocumentを記載したDraft PRを作るStep。
  変更をレビューできる状態にするときに使う。
allowed-tools: >-
  Skill(mami0tsu:task-open-draft-pr)
  Skill(mami0tsu:task-organize-commits)
  Skill(mami0tsu:task-plan-pull-request)
  Skill(mami0tsu:task-push-branch)
  Skill(mami0tsu:task-request-artifact-approval)
  Skill(mami0tsu:task-verify-pull-request)
---

# step-propose-change

検証済みの変更のcommitを関心ごとにまとめてpushし、Draft PRを作る。
作成後のDraft PRを取得し、整理後のcommitがレビュー対象になっていることを確認する。

## 入力

- 検証済みの変更

## 出力

- Draft PRのURL

## 制約

- 修正が必要な指摘を残したまま進めない。
- 入力のcommitが現在のbranchにない場合、またはcommitしていない変更が残っている場合は停止する。
- pull requestをReady for reviewへ変更せず、mergeもしない。
- 参照するスキルが利用できない場合は、そのスキル名を含む`missing-task`を返し、操作を代行しない。

## 手順

### 1. 変更を確認する

検証済みの変更から対象リポジトリ、IssueまたはDocumentへの参照、base branch、作業用branch、対象commit、確認結果を確認する。
リポジトリの設定からpush先のremoteを確認する。

### 2. Commitを整理する

`task-organize-commits`スキルへ検証済みの変更を渡し、整理済みの変更を受け取る。

### 3. BranchをPushする

整理済みの変更、IssueまたはDocumentへの参照、host、canonical repository、base branch、head branch、titleまたは明示的な命名条件を`task-plan-pull-request`スキルへ渡し、template適用済みのDraft PR作成計画を受け取る。
Push計画とDraft PR作成計画をそれぞれの反映値にしたoperation envelopeを作る。
PushとDraft PR作成のoperation IDを分けた成果物計画を、operation envelopeとともに`task-request-artifact-approval`スキルで一度だけ承認してもらう。
Push operationのIDと承認済みoperation envelopeのdigestをpending operationとして確定する。
整理済みの変更、Push計画、成果物の承認結果、対応する承認済みoperation envelope、pending operationを`task-push-branch`スキルへ渡し、push結果を受け取る。

### 4. Draft PRを作る

Draft PR operationのIDと承認済みoperation envelopeのdigestをpending operationとして確定する。
整理済みの変更、push結果、Draft PR作成計画、成果物の承認結果、対応する承認済みoperation envelope、pending operationを`task-open-draft-pr`スキルへ渡し、Draft PRのURLを受け取る。

### 5. Draft PRを確認する

`task-verify-pull-request`スキルへDraft PRのURL、整理済みの変更、Draft PR作成計画、成果物の承認結果、Draft PR作成の承認済みoperation envelopeを渡し、作成したpull requestを取得する。
整理後のcommitが含まれ、Draftになっていることを確認してURLを返す。
