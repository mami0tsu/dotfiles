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
| `factory.json` | loop から渡された設定ファイルの絶対パス |

## 出力

| 成果物 | 内容 |
| --- | --- |
| タスク | Issue に対応するタスク |
| GitHub Issue | タスクを作成してクローズした Issue |

## 手順

### 設定の確認

1. Issue の管理先、タスクのサービスとキー、成果物の出力先を確認する。
   設定が存在しない、不正または不足している場合は、設定パスと不足項目を loop に返して終了する。

### タスクの作成

1. [list-issues.sh](scripts/list-issues.sh) に設定ファイルの絶対パスを渡して実行し、採用を表す状態ラベルが付いたオープンな Issue を取得する。
1. Issue の本文とコメントから、合意したタスクごとの作業範囲、受け入れ条件、出力先と依存関係を確認する。
   状態ラベルが複数付いている場合、内容が不明確な場合や、出力先が設定と一致しない場合は保留する。
1. 設定されたサービスに対応するタスク作成スキルを探す。
   対応するスキルがない場合は理由を返して保留する。
1. 既存タスクと Issue の URL、タスクごとの内容を照合し、作成済みのタスクを確認する。
   照合できない場合は理由を返して保留する。
1. 起票前に Issue の状態とラベルを再確認し、対象から外れていれば保留する。
1. 未作成のタスクについて、サービスに対応する外部スキルを呼び出す。
   サービス、キー、Issue の URL と合意した内容を渡し、タスクから Issue を参照できるようにする。
   タスクには設定内の出力先キーを1つ記録する。
   担当者にはタスク管理サービスで認証中のユーザーを指定する。
   GitHub Issue を作成する場合は、使用中のエージェント名とモデル名を入れた `Written by <Agent Name> (<Model Name>)` を本文の末尾に記載するよう依頼する。
   用途に合う重要な情報には [GitHub のアラート](https://docs.github.com/ja/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts)を使うよう依頼する。
   モデル名を確認できない場合は、推測せずエージェント名だけを記載するよう依頼する。
1. タスク管理サービスに対応する外部スキルで、合意したタスク間の依存関係を設定する。
1. すべてのタスクと依存関係を確認したら、[close-issue.sh](scripts/close-issue.sh) に設定ファイルの絶対パスと Issue 番号を渡して実行し、Issue をクローズする。
1. 作成したタスクとクローズした Issue の URL を返す。
