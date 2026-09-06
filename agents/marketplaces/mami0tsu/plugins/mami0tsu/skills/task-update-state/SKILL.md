---
name: task-update-state
description: >-
  検証済みstateへ外部Object、承認、pending operation、完了済み操作の差分を原子的に保存するTask。
  設計や実装の進行状況を中断と再開に備えて記録するときに使う。
allowed-tools: >-
  Skill(mami0tsu:tool-workflow-state)
---

# task-update-state

検証済みstateの1つのnamespaceへ差分を保存する。
外部操作の前にはpending operationを、成功後には正本識別情報と完了結果を先に記録する。

## 入力

- state checkpoint
- 基準リポジトリ
- 更新namespace
- 更新値

## 出力

- state更新結果

## 制約

- 初期化、検証、直前の更新のいずれかが返したstate checkpointを使う。
- Workflow ID、workflow名、subject kind、subject、state revisionを省略しない。
- 1回の実行で1つのnamespaceだけを更新する。
- 更新値では、対応する保存済みfieldの削除を指定できる。
- token、password、secret、Issue本文、Document本文を保存しない。
- 外部Objectはprovider、host、container、canonical repository、計画上のkey、正本ID、URL、revision、digest、path、branch、commit、操作状態だけを保存する。
- 作業場所情報はrepository identity、作業対象、base branch、起点commit、作業用branch、worktree pathだけを保存する。
- Pending operationと完了済みoperationには、operation IDとoperation envelope digestの組を保存する。
- Operation IDだけでpending operationを完了済みoperationへ移さない。
- revision競合時に上書きしない。

## 手順

### 1. 更新内容を検査する

namespace、更新値、期待するstate revisionを確認し、保存禁止情報がないことを確認する。

### 2. Stateを更新する

検証済みのidentity、revision、基準リポジトリをstate更新操作へ渡し、1つのnamespaceを原子的に更新する。

### 3. 更新結果を読む

更新後stateを読み、新しいrevisionと保存値を照合する。

### 4. 結果を返す

Workflow ID、workflow名、subject kind、subject、更新後revisionを次のstate checkpointとして返す。
Namespace、更新前後のrevision、保存した識別情報をstate更新結果へ含める。
