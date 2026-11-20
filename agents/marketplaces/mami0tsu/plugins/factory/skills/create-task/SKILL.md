---
name: create-task
description: 起票対象の Issue から、設定されたサービスにタスクを作成する。
compatibility: Requires Bash, CUE (cue), and GitHub CLI (gh).
allowed-tools: >-
  Read
  Glob
  Skill
  Bash(bash */skills/create-task/scripts/list-issues.sh *)
  Bash(bash */skills/create-task/scripts/close-issue.sh *)
  Bash(gh issue view *)
---

# Create Task

## 入力

| 項目 | 内容 |
| --- | --- |
| `factory.json` | Issue の管理先、タスクのサービスとキー |

## 出力

| 成果物 | 内容 |
| --- | --- |
| タスク | Issue に対応するタスク |
| GitHub Issue | タスクを作成してクローズした Issue |

## 手順

### 設定の確認

1. 作業ディレクトリとその配下から `factory.json` を探す。
   複数ある場合は対象を確認する。
1. 設定が存在しない場合は、作業ディレクトリの `factory.json` を作成先として [init スキル](../init/SKILL.md)を呼び出す。
1. Issue の管理先、タスクのサービスとキーを確認する。
   設定が不正または不足している場合は、同じパスと不足項目を指定して init スキルを呼び出す。

### タスクの作成

1. [list-issues.sh](scripts/list-issues.sh) に設定ファイルの絶対パスを渡して実行し、`ready` ラベルが付いたオープンな Issue を取得する。
1. Issue の本文とコメントを確認し、合意した内容を把握する。
1. 設定されたサービスに対応するタスク作成スキルを探す。
   対応するスキルがない場合は理由を返して保留する。
1. 既存タスクと Issue の URL を照合し、作成済みのタスクを確認する。
   照合できない場合は理由を返して保留する。
1. 起票前に Issue の状態とラベルを再確認し、対象から外れていれば保留する。
1. 未作成のタスクについて、サービスに対応する外部スキルを呼び出す。
   サービス、キー、Issue の URL と合意した内容を渡し、タスクから Issue を参照できるようにする。
   担当者にはタスク管理サービスで認証中のユーザーを指定する。
   GitHub Issue を作成する場合は、使用中のエージェント名とモデル名を入れた `Written by <Agent Name> (<Model Name>)` を本文の末尾に記載するよう依頼する。
   モデル名を確認できない場合は、推測せずエージェント名だけを記載するよう依頼する。
1. 対応するすべてのタスクの作成を確認したら、[close-issue.sh](scripts/close-issue.sh) に設定ファイルの絶対パスと Issue 番号を渡して実行し、Issue をクローズする。
1. 作成したタスクとクローズした Issue の URL を返す。
