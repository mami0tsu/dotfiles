---
name: task-complete-state
description: >-
  設計または実装の完了条件と外部Objectの検証結果を照合し、保存済みstateを完了状態へ移すTask。
  workflowの成果物を引き渡した最後に使う。
allowed-tools: >-
  Skill(mami0tsu:tool-workflow-state)
---

# task-complete-state

完了証跡を確認し、stateへ完了時刻と最終revisionを記録する。
未完了または曖昧なpending operationが残る場合は完了しない。

## 入力

- state検証結果
- 完了条件
- 完了証跡

## 出力

- state完了結果

## 制約

- 検証済みのWorkflow ID、workflow名、subject kind、subject、Git common directory、state revisionを使う。
- すべての必須成果物について正本ID、URL、revisionまたはdigestを確認する。
- 未解決の差分、未承認の変更、pending operationがある場合は完了しない。
- 完了済みstateを再度変更しない。
- state fileを削除しない。

## 手順

### 1. 完了条件を照合する

必須成果物、状態、関係、検証結果が完了条件を満たすか確認する。

### 2. Pending operationを確認する

未完了または結果の曖昧な外部操作が残っていないことを確認する。

### 3. Stateを完了する

検証済みのidentityとGit common directoryを省略せずにstate完了操作へ渡し、完了時刻と最終結果を記録する。

### 4. 結果を返す

Workflow ID、完了時刻、最終revision、成果物参照をstate完了結果として返す。
