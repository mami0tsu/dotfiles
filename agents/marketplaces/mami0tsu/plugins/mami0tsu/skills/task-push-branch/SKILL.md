---
name: task-push-branch
description: >-
  整理済みの作業用branchを指定されたremoteへpushし、対象commitが反映されたことを確認するTask。
  Draft PRを作る前にbranchを公開するときに使う。
allowed-tools: >-
  Skill
  Skill(mami0tsu:tool-artifact-digest)
---

# task-push-branch

整理済みの作業用branchを、履歴を書き換えずにpushする。
push後はremote branchの対象commitを確認する。

## 入力

- 整理済みの変更
- Push計画
- 成果物の承認結果
- 承認済みoperation envelope
- operation IDとdigestを含むpending operation

## 出力

- push結果

## 制約

- 入力のcommitが現在のbranchにない場合はpushしない。
- 承認済みoperation envelopeのoperation IDとdigestが成果物の承認結果に含まれない場合はpushしない。
- Pending operationのoperation IDとdigestが承認済みoperation envelopeおよび成果物の承認結果と一致しない場合はpushしない。
- Push計画が承認済みoperation envelopeの反映値と一致しない場合はpushしない。
- commitしていない変更が残っている場合はpushしない。
- push先のremoteとbranchを明示する。
- Push先のhostとcanonical repositoryをPush計画と一致させる。
- remote branchの履歴を書き換えない。
- push先に上書きできない履歴がある場合は停止する。
- pull requestを作成しない。

## 手順

### 1. 作業状態を確認する

現在のリポジトリ、branch、最新commit、変更済みファイルを整理済みの変更と照合する。

### 2. Push先を確認する

承認済みoperation envelope全体を共通のJSON digest操作へ渡し、そのoperation IDとdigestが成果物の承認結果およびpending operationと一致することを確認する。
Push計画がoperation envelopeの反映値と同一であることを確認する。
入力とリポジトリの設定から、push先のremote、host、canonical repository、branchを特定する。
Hostとcanonical repositoryをPush計画と照合する。
push先を1つに決められない場合は停止する。

### 3. Remote branchを確認する

remote branchを安全に更新できることを確認する。
安全に更新できない場合は履歴を書き換えず停止する。

### 4. Branchをpushする

remoteとbranchを明示してpushする。

### 5. Push結果を返す

Remote、host、canonical repository、remote branch、反映されたcommit、pushの結果を返す。
