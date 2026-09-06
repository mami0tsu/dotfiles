---
name: task-plan-pull-request
description: >-
  整理済みの変更からtitleと最終本文を組み立て、承認に使うDraft PR作成計画を作るTask。
  Pull request templateを反映した内容を外部作成前に固定するときに使う。
allowed-tools: >-
  Glob
  Read
  Skill(mami0tsu:tool-artifact-digest)
  Skill(mami0tsu:tool-gh)
---

# task-plan-pull-request

整理済みの変更と参照元から、作成時にそのまま使えるDraft PRの内容を確定する。
Templateの適用と本文の編集は、成果物の承認前に完了させる。

## 入力

- 整理済みの変更
- IssueまたはDocumentへの参照
- hostとcanonical repository
- base branchとhead branch
- title、またはtitleを決める明示的な命名条件

## 出力

- Draft PR作成計画

## 制約

- Pull requestを作成または変更しない。
- Host、canonical repository、base branch、head branch、title、本文、対象commitを推測で補わない。
- Titleが与えられていない場合は、明示的な命名条件がなければ停止する。
- Template適用後の本文を最終本文とし、後続処理による再構成を前提にしない。

## 手順

### 1. 入力を確認する

Host、canonical repository、IssueまたはDocumentへの参照、base branch、head branch、対象commit、変更内容、確認結果、titleまたは命名条件を整理する。

### 2. Templateを確認する

リポジトリのpull request templateがある場合は、その構成を取得する。
利用できるtemplateがない場合は、Draft PR作成に利用する方法が提供するtemplateを取得する。

### 3. 内容を作る

Titleが入力された場合はその値を使う。
Titleがない場合は、明示的な命名条件を変更の目的とIssueまたはDocumentの識別情報へ適用してtitleを作る。
変更の目的、参照元、変更内容、レビュー観点、確認結果をtemplateへ反映する。
完成した本文を共通のtext digest操作へ渡し、本文digestを求める。

### 4. 計画を返す

Host、canonical repository、base branch、head branch、title、最終本文、本文digest、対象commit、変更内容、確認結果をDraft PR作成計画として返す。
