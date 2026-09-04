---
name: task-read-issue
description: >-
  Jira、Linear、GitHubのIssueをrelationとともに取得し、共通形式へ正規化するTask。
  既存Issueの内容、親子関係、依存関係、状態を確認するときに使う。
allowed-tools: >-
  Skill(mami0tsu:tool-gh)
  mcp__atlassian__*
  mcp__linear__*
---

# task-read-issue

指定されたIssueを一件取得し、provider固有の値を共通形式へ変換する。
取得中はIssueとrelationを変更しない。

## 入力

- Issueのproviderと参照

## 出力

- Issue取得結果

## 制約

- providerとIssueを推測しない。
- 一件に確定できない検索結果をIssue取得結果として返さない。
- Issue、comment、relationを変更しない。
- provider固有の追加fieldを共通fieldの代わりに使わない。

## 手順

### 1. Issueを特定する

provider、container、IDまたは正本URLからIssueを一件に確定する。

### 2. Issueを取得する

title、description、assignee、状態、親、子、`blockedBy`、`blocks`、正本URL、更新時刻を取得する。

### 3. 状態を正規化する

provider上の状態名と状態種別を保持し、設計中、進行中、設計完了、未着手で実装可能の意味上の状態と区別する。

### 4. 結果を返す

provider、container、ID、URL、title、description、assignee、状態、relation、更新時刻をIssue取得結果として返す。
