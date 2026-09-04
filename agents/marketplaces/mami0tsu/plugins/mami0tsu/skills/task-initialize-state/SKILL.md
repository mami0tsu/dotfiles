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

- state identity
- 基準リポジトリ

## 出力

- state初期化結果

## 制約

- Workflow ID、workflow名、subject kind、subjectを明示する。
- subjectには要求本文ではなく、正本URL、外部ID、または要求digestを使う。
- 同じWorkflow IDのstateが存在する場合は上書きしない。
- token、password、secret、Issue本文、Document本文を保存しない。
- Git common directory以外へ正本stateを作らない。

## 手順

### 1. Identityを確認する

Workflow ID、workflow名、subject kind、subject、基準リポジトリを入力から確定する。

### 2. Identityを検査する

Identityに本文やsecretが含まれず、基準リポジトリで一意に作業を識別できることを確認する。

### 3. Stateを作る

利用可能なstate初期化操作を使い、基準リポジトリへstateを作る。

### 4. 結果を返す

Workflow ID、state path、identity、revisionをstate初期化結果として返す。
