---
name: task-link-issues
description: >-
  承認済みのIssue関係計画に従い、Jira、Linear、GitHubのIssueへ親子関係または依存関係を反映するTask。
  作成済みIssue同士をtracking構成へまとめるときや、実装順序をblockedByで表すときに使う。
allowed-tools: >-
  Skill(mami0tsu:tool-artifact-digest)
  Skill(mami0tsu:tool-gh)
  mcp__atlassian__*
  mcp__linear__*
---

# task-link-issues

Issue間の関係を一種類ずつ反映する。
既存関係を先に読み、承認済みの差分だけを追加または削除する。

## 入力

- Issue関係計画
- 計画上のIssue keyからprovider、container、GitHubのhostとcanonical repository、正本IDへの対応表
- 対応表の根拠となる検証済みIssue結果
- 成果物の承認結果
- 承認済みoperation envelope
- operation IDとdigestを含むpending operation

## 出力

- Issue関係更新結果

## 制約

- 1回の実行で親子関係または依存関係のどちらか1種類だけを扱う。
- 対象Issueは同じproviderとcontainerに属するものだけを扱い、GitHubではhostとcanonical repositoryも一致させる。
- 管理対象として承認されていないIssueと関係を変更しない。
- Issue関係計画の対象は計画上のIssue keyで固定し、作成後の正本IDを計画へ書き戻さない。
- 対応表にないIssue keyや、計画と異なるprovider、container、GitHubのhost、canonical repositoryの対応を使わない。
- GitHubの正本IDには正の整数Issue番号を使い、GraphQL node IDを使わない。
- 既存関係を推測で削除しない。
- 承認済みoperation envelopeのoperation IDとdigestが成果物の承認結果に含まれない場合は変更しない。
- Pending operationのoperation IDとdigestが承認済みoperation envelopeおよび成果物の承認結果と一致しない場合は変更しない。
- 関係計画が承認済みoperation envelopeの反映値と一致しない場合は変更しない。
- 一部の更新に失敗しても、成功済みの関係を戻さない。
- 更新結果が曖昧な場合は同じ操作を再実行しない。

## 手順

### 1. 現在の関係を読む

対象Issueを再取得し、親、子、依存先、依存元を記録する。

### 2. 差分を決める

承認済みoperation envelope全体を共通のJSON digest操作へ渡し、そのoperation IDとdigestが成果物の承認結果およびpending operationと一致することを確認する。
Issue関係計画がoperation envelopeの反映値と同一であることを確認する。
対応表の各Issueを正本IDで取得し、計画上のIssue key、provider、container、GitHubのhostとcanonical repositoryが検証済みIssue結果と現在の正本に一致することを確認する。
現在の関係と承認済み計画を比較する。
追加対象と、明示的に承認された削除対象だけを抽出する。

### 3. 関係を反映する

計画上のIssue keyを検証済みの正本IDへ解決し、providerに対応する利用可能な操作で一種類の関係を一件ずつ反映する。
各操作の正本IDと結果を記録する。

### 4. 結果を確認する

対象Issueを再取得し、成功済みの関係と未反映の差分を照合する。

### 5. 結果を返す

関係の種類、追加済み、削除済み、未反映、曖昧な操作をIssue関係更新結果として返す。
