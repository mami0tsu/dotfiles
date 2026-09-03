---
name: task-open-draft-pr
description: >-
  整理済みの変更とpush結果からDraft PRを作成するTask。
  検証済みの変更をレビューできる状態にするときに使う。
allowed-tools: >-
  Glob
  Read
  Skill
---

# task-open-draft-pr

整理済みの変更を説明するDraft PRを一つ作成する。
同じhead branchのpull requestがすでにある場合は、重複して作成しない。

## 入力

- 整理済みの変更
- push結果

## 出力

- Draft PRのURL

## 制約

- head branchがremoteへpushされていない場合は作成しない。
- base branch、head branch、title、本文に必要な情報を推測で補わない。
- pull requestをReady for reviewにしない。
- pull requestをmergeしない。
- 既存のpull requestを変更しない。

## 手順

### 1. 作成内容を確認する

対象リポジトリ、IssueまたはDocumentへの参照、base branch、head branch、対象commit、変更内容、確認結果が入力に含まれていることを確認する。
head branchと対象commitがpush結果に含まれていることを確認する。
不足がある場合はpull requestを作らず停止する。

### 2. Head branchを確認する

remoteのhead branchが存在し、入力で指定されたcommitを含むことを確認する。

### 3. 既存のpull requestを確認する

同じリポジトリとhead branchを使うpull requestを検索する。
見つかった場合は新しく作成せず、そのURLを返す。

### 4. 本文を作る

変更の目的、IssueまたはDocumentへの参照、変更内容、レビュー観点、確認結果を本文に記載する。
リポジトリのpull request templateがある場合は、その構成を使う。
利用できるtemplateがない場合は、Draft PR作成に利用する方法が提供するtemplateを使う。

### 5. Draft PRを作る

入力から作成したbase branch、head branch、title、本文を使ってDraft PRを作成する。

### 6. Draft PRのURLを返す

作成されたDraft PRのURLを返す。
