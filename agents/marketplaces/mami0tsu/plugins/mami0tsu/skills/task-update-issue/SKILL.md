---
name: task-update-issue
description: >-
  承認済みのIssue変更をJira、Linear、GitHubの一件へ反映し、更新後の状態を返すTask。
  Issueの本文、担当者、状態などを期待する最終値へ変更するときに使う。
allowed-tools: >-
  Skill(mami0tsu:tool-artifact-digest)
  Skill(mami0tsu:tool-gh)
  mcp__atlassian__*
  mcp__linear__*
---

# task-update-issue

Issueの現在値を確認し、承認済みfieldの差分だけを一件へ反映する。
承認範囲にないfieldとrelationは保持する。

## 入力

- Issue更新計画
- 成果物の承認結果
- 承認済みoperation envelope
- operation IDとdigestを含むpending operation

## 出力

- Issue更新結果

## 制約

- 承認済みoperation envelopeのoperation IDとdigestが成果物の承認結果に含まれない場合は更新しない。
- Pending operationのoperation IDとdigestが承認済みoperation envelopeおよび成果物の承認結果と一致しない場合は更新しない。
- 更新計画が承認済みoperation envelopeの反映値と一致しない場合は更新しない。
- GitHubではhostとcanonical repositoryを省略せず、承認済みの保存先と一致させる。
- GitHubではIssue更新計画の正本IDに正の整数Issue番号を使い、GraphQL node IDを使わない。
- 承認済みoperation envelopeの期待する現在値と実際の値が異なる場合は更新しない。
- 計画にないfieldとrelationを変更しない。
- 更新失敗時に開始前の値へ自動で戻さない。

## 手順

### 1. 現在値を取得する

Issueを一件取得し、ID、URL、更新対象field、更新時刻を確認する。

### 2. 更新条件を確認する

承認済みoperation envelope全体を共通のJSON digest操作へ渡し、そのoperation IDとdigestが成果物の承認結果およびpending operationと一致することを確認する。
Issue更新計画がoperation envelopeの反映値と同一であることを確認する。
現在値のdigestと承認済みoperation envelopeの期待する現在値を比較し、承認済みの差分を求める。

### 3. Issueを更新する

差分がある承認済みfieldだけを更新する。

### 4. 結果を確認する

同じIssueを再取得し、更新対象fieldを期待値と比較する。

### 5. 結果を返す

計画上のIssue key、provider、container、GitHubの場合はhostとcanonical repository、正本ID、URL、変更したfield、更新後の値、操作結果をIssue更新結果として返す。
GitHubの正本IDには正の整数Issue番号を返す。
