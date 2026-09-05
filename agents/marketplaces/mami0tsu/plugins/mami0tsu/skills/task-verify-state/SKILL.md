---
name: task-verify-state
description: >-
  保存済みstateを読み、期待するidentity、外部Object、承認、pending operationと現在の作業が一致するか検証するTask。
  中断した設計や実装を再開する前と、外部書き込みの直前に使う。
allowed-tools: >-
  Skill(mami0tsu:tool-workflow-state)
---

# task-verify-state

基準リポジトリのstateを読み、現在の入力と安全に結び付ける。
一致しないstateを更新せず、差分を返して停止する。

## 入力

- Workflow ID
- 期待するstate identity
- 現在の作業情報

## 出力

- state検証結果とstate checkpoint

## 制約

- workflow名、subject kind、subjectの完全一致を要求する。
- 記録済みの外部Objectを正本IDとURLで照合する。
- 承認対象digestと予定操作が変わっている場合は承認を無効とする。
- pending operationが曖昧な場合は外部操作を再実行しない。
- 検証中にstateを変更しない。

## 手順

### 1. Stateを読む

利用可能なstate検証操作を使い、Workflow IDに対応するstateを取得する。

### 2. Identityを照合する

workflow名、subject kind、subject、基準リポジトリを期待値と比較する。

### 3. 進行状況を照合する

外部Object、revision、digest、承認、完了済み操作、pending operationを現在の作業情報と比較する。

### 4. 結果を返す

Workflow ID、workflow名、subject kind、subject、Git common directory、state path、最新revisionをstate checkpointとして返す。
一致した項目、差分、再開可能な操作、人間の対応が必要な操作をstate検証結果として返す。
