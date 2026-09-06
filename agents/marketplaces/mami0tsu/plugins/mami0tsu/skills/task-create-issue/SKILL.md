---
name: task-create-issue
description: >-
  承認済みのIssue作成内容をJira、Linear、GitHubの一つへ反映し、作成された正本IDとURLを返すTask。
  tracking、設計、実装、standaloneのIssueを一件作るときに使う。
allowed-tools: >-
  Skill(mami0tsu:tool-artifact-digest)
  Skill(mami0tsu:tool-gh)
  mcp__atlassian__*
  mcp__linear__*
---

# task-create-issue

承認済みの内容からIssueを一件だけ作る。
同じ入力から複数Issueを作らず、結果が曖昧な場合は再作成しない。

## 入力

- Issue作成計画
- 成果物の承認結果
- operation IDとdigestを含むpending operation

## 出力

- Issue作成結果

## 制約

- provider、container、title、description、状態を推測で補わない。
- JiraではIssue typeとproject metadataが要求するすべての必須fieldを推測で補わない。
- 作成計画のoperation IDとdigestが成果物の承認結果に含まれない場合は作成しない。
- Pending operationのoperation IDとdigestが作成計画および成果物の承認結果と一致しない場合は作成しない。
- pending operationが記録されていない場合は作成しない。
- 1回の実行で1件だけ作る。
- 作成結果から正本IDを確認できない場合は再実行しない。

## 手順

### 1. 作成内容を確認する

作成計画を共通のJSON digest操作へ渡し、計画、成果物の承認結果、pending operationのoperation IDとdigestが三者で一致することを確認する。
Provider、container、title、description、assignee、provider上の状態、意味上の状態を承認結果と照合する。
Jiraでは承認済みのIssue typeと必須fieldをproject metadataと照合し、不足または不一致があれば作成しない。

### 2. Issueを作る

providerに対応する利用可能な操作で、承認済みfieldだけを指定してIssueを一件作る。

### 3. 正本を取得する

作成応答からIDとURLを取得し、そのIDでIssueを再取得する。
正本IDが曖昧な場合は、同じcontainerからtitleと作成時刻が近い候補を列挙する。

### 4. 結果を返す

provider、container、ID、URL、作成後のfield、操作結果をIssue作成結果として返す。
結果が曖昧な場合は、候補と、再開時に人間が正しいIssueを対応付ける必要があることを返す。
