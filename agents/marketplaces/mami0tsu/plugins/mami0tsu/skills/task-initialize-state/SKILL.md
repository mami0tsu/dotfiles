---
name: task-initialize-state
description: >-
  基準リポジトリのGit common directoryへ作業状態を新規作成し、再開に使うidentityと保存先を確定するTask。
  設計や実装を複数turn、複数worktreeにまたがって始めるときに使う。
allowed-tools: >-
  Skill(mami0tsu:tool-workflow-state)
---

# task-initialize-state

作業を一意に識別するstateを基準リポジトリへ作成する。
本文やsecretを保存せず、外部Objectの識別情報と進行状況だけを保持する。

## 入力

- workflow名、subject kind、subject
- Workflow ID（指定する場合）
- 基準リポジトリ

## 出力

- state checkpoint

## 制約

- workflow名、subject kind、subjectを明示する。
- 新規作業でWorkflow IDがない場合は、state初期化操作に安全なIDを生成させる。
- subjectには要求本文ではなく、正本URL、外部ID、または`sha256:`で始まる要求digestを使う。
- 同じWorkflow IDのstateが存在する場合は上書きしない。
- token、password、secret、Issue本文、Document本文を保存しない。
- Git common directory以外へ正本stateを作らない。

## 手順

### 1. Identityを確認する

workflow名、subject kind、subject、基準リポジトリを入力から確定する。
Workflow IDが指定されている場合は、その値も確定する。

### 2. Identityを検査する

Identityに本文やsecretが含まれず、基準リポジトリで一意に作業を識別できることを確認する。

### 3. Stateを作る

利用可能なstate初期化操作を使い、基準リポジトリへstateを作る。
Workflow IDがない場合は初期化操作の生成結果を採用し、呼び出し元で別のIDを作らない。

### 4. 結果を返す

Workflow ID、workflow名、subject kind、subject、Git common directory、state path、revisionをstate checkpointとして返す。
