---
name: task-verify-issue
description: >-
  Jira、Linear、GitHubのIssueを正本から再取得し、期待するfield、関係、意味上の状態と一致するか検証するTask。
  Issue作成や更新の直後と、設計を実装へ引き渡す直前に使う。
allowed-tools: >-
  Skill(mami0tsu:tool-gh)
  mcp__atlassian__*
  mcp__linear__*
---

# task-verify-issue

Issueの現在値を読み取り、期待値との差分を返す。
検証中にIssueを変更しない。

## 入力

- 検証対象Issue
- 期待するIssue状態

## 出力

- Issue検証結果

## 制約

- 入力にあるprovider、container、正本IDを使う。
- provider固有の状態名と意味上の状態を区別する。
- 本文は正規化したdigestでも比較し、空白差だけで一致と判断しない。
- 親子関係と依存関係を別々に検証する。
- 差分があってもIssueを更新しない。

## 手順

### 1. Issueを取得する

正本IDでIssueを再取得し、URL、field、本文、状態、親子関係、依存関係を読む。

### 2. 内容を比較する

title、本文digest、assignee、label、正本参照、対象リポジトリを期待値と比較する。

### 3. 関係を比較する

親、子、blockedBy、blocksを正本IDで比較する。

### 4. 状態を比較する

provider上の状態を意味上の状態へ対応付け、期待する状態と一致するか確認する。

### 5. 結果を返す

取得した正本URL、revision、本文digest、一致した項目、差分、意味上の状態をIssue検証結果として返す。
