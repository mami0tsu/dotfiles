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

- Issueのprovider、container、正本IDまたは正本URL
- GitHubの場合はhostとcanonical repository、および正の整数Issue番号を10進数の文字列に変換した正本IDまたは正本URL

## 出力

- Issue取得結果

## 制約

- providerとIssueを推測しない。
- 一件に確定できない検索結果をIssue取得結果として返さない。
- Issue、comment、relationを変更しない。
- provider固有の追加fieldを共通fieldの代わりに使わない。
- GitHubの正本IDには、正の整数Issue番号を10進数の文字列に変換した値を使い、GraphQL node IDを使わない。

## 手順

### 1. Issueを特定する

Provider、container、GitHubの場合はhostとcanonical repository、正本IDまたは正本URLからIssueを一件に確定する。
GitHubでは正本IDを正の整数Issue番号を表す10進数の文字列として扱う。

### 2. Issueを取得する

title、description、assignee、状態、親、子、`blockedBy`、`blocks`、設計正本の種類、ID、URL、revision、digest、対象リポジトリ、更新時刻を取得する。

### 3. 状態を正規化する

provider上の状態名と状態種別を保持し、設計中、進行中、設計完了、未着手で実装可能の意味上の状態と区別する。

### 4. 結果を返す

Provider、container、GitHubの場合はhostとcanonical repository、正本ID、URL、title、description、assignee、状態、relation、設計正本の種類、ID、URL、revision、digest、対象リポジトリ、更新時刻をIssue取得結果として返す。
GitHubの正本IDには、正の整数Issue番号を10進数の文字列に変換した値を返す。
