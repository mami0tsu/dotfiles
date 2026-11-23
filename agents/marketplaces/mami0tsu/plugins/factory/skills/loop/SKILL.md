---
name: loop
description: factory のスキルを設定された間隔で繰り返し実行する。
compatibility: Requires Bash and CUE (cue).
allowed-tools: >-
  Read
  Glob
  Agent
  Task
  Skill
  Bash(bash */skills/loop/scripts/check-config.sh *)
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
   現在は [inspect スキル](../inspect/SKILL.md)、[research スキル](../research/SKILL.md)、[create-task スキル](../create-task/SKILL.md)、[review-pr スキル](../review-pr/SKILL.md)、[respond スキル](../respond/SKILL.md)、[implement スキル](../implement/SKILL.md)が対象である。
1. 実行対象ごとに、loop の起動時を最初の実行予定時刻とする。
1. inspect の実行予定時刻になったら、前回の inspect の完了後に新規候補の調査が可能か確認する。
   設定パスと確認の依頼を inspect に渡す。
1. 調査が可能な場合は、設定された各リポジトリの URL を [setup-repository スキル](../setup-repository/SKILL.md)に渡す。
   準備したパスと設定パスを inspect に渡し、調査を依頼する。
1. research の実行予定時刻になったら、前回の research の完了後に調査対象の Issue を取得する。
   設定パスと取得の依頼を research に渡す。
1. 設定された各リポジトリを setup-repository で準備し、Issue ごとに research を実行する。
   設定パス、準備したリポジトリのパスと対象 Issue の URL を渡す。
   同じ Issue は並行して調査しない。
1. implement の実行予定時刻になったら、implement に対象タスクとリポジトリの一覧を取得させる。
1. 対象タスクのリポジトリの URL を setup-repository に渡す。
   準備したパスとコミットをタスクとともに implement に渡し、実装を依頼する。
1. inspect、research と implement 以外の実行予定時刻になったスキルをサブエージェントに実行させる。
   `factory.json` が必要なスキルには、その絶対パスを渡す。
1. すべてのスキルについて、全体とスキルごとの同時処理数の上限に従う。
   全体またはスキルごとの同時処理数が上限に達している場合は、空きができた時点で起動する。
   次の実行予定時刻はスキルの起動時刻に実行間隔を加えた時刻とする。
   inspect と research はそれぞれ調査の組を開始した時刻を使う。
   同じコメントには並行して返信しない。
   同じタスクは並行して実装しない。
   同じリポジトリの準備は並行して実行しない。
   準備を開始してから inspect または research が調査を終えるまで、そのリポジトリを更新しない。
1. inspect から候補の一覧、または research から既存 Issue の調査結果を受け取ったら、対象ごとに [review-issue スキル](../review-issue/SKILL.md)をサブエージェントに実行させる。
   レビュー対象、調査の根拠と `factory.json` の絶対パスを渡す。
   全体とスキルごとの同時処理数の上限に従う。
   同じ対象の処理は、調査開始から投稿まで重複して実行しない。
1. 指摘がある場合は、レビュー結果を元のスキルに渡して修正を依頼し、修正された結果を再びレビューする。
1. 指摘がない Issue の候補は、設定とともに [create-issue スキル](../create-issue/SKILL.md)へ渡して登録を依頼する。
   Issue の上限が指定されている場合は、create-issue を同時に1件だけ実行する。
1. 指摘がない追加調査結果は、Issue の URL とともに [respond スキル](../respond/SKILL.md)へ渡して記録を依頼する。
1. implement が完了したら、PR の作成情報と検証結果を [create-pr スキル](../create-pr/SKILL.md)へ渡して PR の作成を依頼する。
   タスク管理サービスに対応するスキルを使い、タスクに PR の URL を記録する。
1. スキルから設定の不備を受け取った場合は、設定パスと不足項目を指定して init スキルを呼び出す。
   不備が解消したら、同じスキルを再実行する。
1. create-issue が Issue の上限に達した場合は、その候補の登録を見送る。
   inspect の次の実行時に上限を再確認する。
1. サブエージェントの完了後に結果を受け取り、上限による見送り以外で保留または失敗した場合は理由を返して終了する。
1. 次の実行予定時刻または実行中のスキルの完了を待ち、停止を求められるまで処理を繰り返す。
