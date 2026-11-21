---
name: loop
description: factory のスキルを設定された間隔で繰り返し実行する。
compatibility: Requires Bash, CUE (cue), and GitHub CLI (gh).
allowed-tools: >-
  Read
  Glob
  Agent
  Task
  Skill
  Bash(bash */skills/loop/scripts/check-config.sh *)
  Bash(bash */hooks/check-research-issues.sh *)
  Bash(sleep *)
---

# Loop

## 入力

| 項目 | 内容 |
| --- | --- |
| `factory.json` | スキルごとの実行間隔と同時処理数を指定した設定 |

## 手順

### 設定の確認

1. 作業ディレクトリとその配下から `factory.json` を探す。
   複数ある場合は対象を確認する。
1. 設定が存在しない場合は、作業ディレクトリの `factory.json` を作成先として [init スキル](../init/SKILL.md)を呼び出す。
1. [check-config.sh](scripts/check-config.sh) に設定ファイルの絶対パスを渡して実行し、実行間隔と同時処理数を取得する。
   設定に不備がある場合は init スキルを呼び出し、設定を再取得する。

### スキルの実行

1. `intervalSeconds` が設定されたスキルのうち、実装済みのスキルを実行対象とする。
   現在は [research スキル](../research/SKILL.md)、[create-task スキル](../create-task/SKILL.md)、[review-pr スキル](../review-pr/SKILL.md)、[respond スキル](../respond/SKILL.md)が対象である。
1. 実行対象ごとに、loop の起動時を最初の実行予定時刻とする。
1. research の実行予定時刻になり、`maxOpenIssues` が指定されている場合は、[上限確認フック](../../hooks/check-research-issues.sh) に設定ファイルの絶対パスを渡して実行する。
   終了コードが 2 の場合は research の実行を見送り、実行間隔が経過した後に再び確認する。
   件数を取得できない場合は理由を返して終了する。
1. 実行予定時刻になったスキルをサブエージェントに実行させる。
   全体またはスキルごとの同時処理数が上限に達している場合は、空きができた時点で起動する。
   次の実行予定時刻はスキルの起動時刻に実行間隔を加えた時刻とする。
   research に Issue の上限が設定されている場合、research は同時に1件だけ実行する。
   同じコメントには並行して返信しない。
1. スキルから Issue 作成前の候補または既存 Issue の追加調査結果を受け取ったら、対象ごとに [review-issue スキル](../review-issue/SKILL.md)をサブエージェントに実行させる。
   レビュー対象と調査の根拠を渡す。
   全体とスキルごとの同時処理数の上限に従う。
   同じ対象はレビューから登録まで並行して処理しない。
1. 指摘がある場合は、レビュー結果を元のスキルに渡して修正を依頼し、修正された結果を再びレビューする。
1. 指摘がない場合は、レビュー対象と結果を元のスキルに渡す。
   Issue の候補では登録を依頼する。
1. サブエージェントの完了後に結果を受け取り、保留または失敗した場合は理由を返して終了する。
   research が Issue の上限に達した場合は、research の実行を見送り、実行間隔が経過した後に再び確認する。
1. 次の実行予定時刻または実行中のスキルの完了を待ち、停止を求められるまで処理を繰り返す。
