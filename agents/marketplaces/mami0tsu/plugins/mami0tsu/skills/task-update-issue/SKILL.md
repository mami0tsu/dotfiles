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
- operation IDとdigestを含むpending operation

## 出力

- Issue更新結果

## 制約

- 更新計画のoperation IDとdigestが成果物の承認結果に含まれない場合は更新しない。
- pending operationの期待する現在値と実際の値が異なる場合は更新しない。
- 計画にないfieldとrelationを変更しない。
- 更新失敗時に開始前の値へ自動で戻さない。

## 手順

### 1. 現在値を取得する

Issueを一件取得し、ID、URL、更新対象field、更新時刻を確認する。

### 2. 更新条件を確認する

更新計画を共通のJSON digest操作へ渡し、operation IDに対応する承認済みdigestと照合する。
現在値のdigestとpending operationの期待値を比較し、承認済みの差分を求める。

### 3. Issueを更新する

差分がある承認済みfieldだけを更新する。
GitHubで本文を更新する場合は、承認済み本文を権限`0600`の一時body fileへ保存し、そのpathをIssue更新操作へ渡す。
GitHub操作の成否にかかわらず、直後に一時body fileを削除する。
本文または一時fileのpathをstateへ保存しない。

### 4. 結果を確認する

同じIssueを再取得し、更新対象fieldを期待値と比較する。

### 5. 結果を返す

IssueのID、URL、変更したfield、更新後の値、操作結果をIssue更新結果として返す。
