---
name: task-open-draft-pr
description: >-
  整理済みの変更とpush結果からDraft PRを作成するTask。
  検証済みの変更をレビューできる状態にするときに使う。
allowed-tools: >-
  Skill
  Skill(mami0tsu:tool-artifact-digest)
  Skill(mami0tsu:tool-gh)
---

# task-open-draft-pr

整理済みの変更を説明するDraft PRを1つ作成する。
同じhead branchのpull requestがすでにある場合は、重複して作成しない。

## 入力

- 整理済みの変更
- push結果
- Draft PR作成計画
- 成果物の承認結果
- 承認済みoperation envelope
- operation IDとdigestを含むpending operation

## 出力

- Draft PRのURL

## 制約

- head branchがremoteへpushされていない場合は作成しない。
- 承認済みoperation envelopeのoperation IDとdigestが成果物の承認結果に含まれない場合は作成しない。
- Pending operationのoperation IDとdigestが承認済みoperation envelopeおよび成果物の承認結果と一致しない場合は作成しない。
- Draft PR作成計画が承認済みoperation envelopeの反映値と一致しない場合は作成しない。
- base branch、head branch、title、本文に必要な情報を推測で補わない。
- pull requestをReady for reviewにしない。
- pull requestをmergeしない。
- 既存のpull requestを変更しない。

## 手順

### 1. 作成内容を確認する

承認済みoperation envelope全体を共通のJSON digest操作へ渡し、そのoperation IDとdigestが成果物の承認結果およびpending operationと一致することを確認する。
Draft PR作成計画がoperation envelopeの反映値と同一であることを確認する。
Host、canonical repository、IssueまたはDocumentへの参照、base branch、head branch、title、本文、対象commit、変更内容、確認結果が入力に含まれていることを確認する。
head branch、対象commit、host、canonical repositoryがpush結果と一致することを確認する。
不足がある場合はpull requestを作らず停止する。

### 2. Head branchを確認する

remoteのhead branchが存在し、入力で指定されたcommitを含むことを確認する。

### 3. 既存のpull requestを確認する

同じhost、canonical repository、head branchを使うpull requestを検索する。
見つかった場合はhost、canonical repository、base branch、head branch、title、正規化した本文、Draft状態を承認済み計画と照合する。
すべて一致した場合だけ新しく作成せずにURLを返し、不一致がある場合は既存のpull requestを変更せず停止する。

### 4. 承認済み本文を固定する

Draft PR作成計画にある本文を共通のtext digest操作へ渡し、承認済みの本文digestと再度照合する。
承認後にtemplateを適用したり、本文を要約または再構成したりしない。

### 5. Draft PRを作る

承認済み計画のhostとcanonical repositoryを明示し、base branch、head branch、title、最終本文をそのまま使ってDraft PRを作成する。

### 6. Draft PRのURLを返す

作成されたDraft PRのURLを返す。
