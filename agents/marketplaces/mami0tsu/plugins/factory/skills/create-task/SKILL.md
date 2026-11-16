---
name: create-task
description: 起票対象のアイデアから、設定されたサービスにタスクを作成する。
compatibility: Requires Bash, CUE (cue), and GitHub CLI (gh).
allowed-tools: >-
  Read
  Glob
  Skill
  Bash(bash */skills/create-task/scripts/list-ideas.sh *)
  Bash(bash */skills/create-task/scripts/close-idea.sh *)
  Bash(gh issue view *)
---

# Create Task

## 入力

| 項目 | 内容 |
| --- | --- |
| `factory.json` | アイデアの管理先、タスクのサービスとキー |

## 出力

| 成果物 | 内容 |
| --- | --- |
| タスク | アイデアに対応するタスク |
| GitHub Issue | タスクを作成してクローズしたアイデア |

## 手順

### 設定の確認

1. 作業ディレクトリとその配下から `factory.json` を探す。
   複数ある場合は対象を確認する。
1. 設定が存在しない場合は、作業ディレクトリの `factory.json` を作成先として [init スキル](../init/SKILL.md)を呼び出す。
1. アイデアの管理先、タスクのサービスとキーを確認する。
   設定が不正または不足している場合は、同じパスと不足項目を指定して init スキルを呼び出す。

### タスクの作成

1. [list-ideas.sh](scripts/list-ideas.sh) に設定ファイルの絶対パスを渡して実行し、`ready` ラベルが付いたオープンなアイデアを取得する。
1. アイデアの本文とコメントを確認し、合意した内容を把握する。
1. 設定されたサービスに対応するタスク作成スキルを探す。
   対応するスキルがない場合は理由を返して保留する。
1. 既存タスクとアイデアの URL を照合し、作成済みのタスクを確認する。
   照合できない場合は理由を返して保留する。
1. 起票前にアイデアの状態とラベルを再確認し、対象から外れていれば保留する。
1. 未作成のタスクについて、サービスに対応する外部スキルを呼び出す。
   サービス、キー、アイデアの URL と合意した内容を渡し、タスクからアイデアを参照できるようにする。
   担当者にはタスク管理サービスで認証中のユーザーを指定する。
1. 対応するすべてのタスクの作成を確認したら、[close-idea.sh](scripts/close-idea.sh) に設定ファイルの絶対パスと Issue 番号を渡して実行し、アイデアをクローズする。
1. 作成したタスクとクローズしたアイデアの URL を返す。
