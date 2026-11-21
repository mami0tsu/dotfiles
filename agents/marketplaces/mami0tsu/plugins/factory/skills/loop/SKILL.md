---
name: loop
description: factory のスキルを設定された間隔で繰り返し実行する。
compatibility: Requires Bash, CUE (cue), Git, ghq, and GitHub CLI (gh).
allowed-tools: >-
  Read
  Glob
  Agent
  Task
  Skill
  Bash(bash */skills/loop/scripts/check-config.sh *)
  Bash(bash */skills/loop/scripts/prepare-repository.sh *)
  Bash(bash */skills/loop/scripts/list-research-issues.sh *)
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
   現在は [research スキル](../research/SKILL.md)、[create-task スキル](../create-task/SKILL.md)、[review-pr スキル](../review-pr/SKILL.md)、[respond スキル](../respond/SKILL.md)、[implement スキル](../implement/SKILL.md)が対象である。
1. 実行対象ごとに、loop の起動時を最初の実行予定時刻とする。
1. research の実行予定時刻になったら、前回の research の完了後に次の調査を開始する。
   各リポジトリについて [prepare-repository.sh](scripts/prepare-repository.sh) に設定ファイルの絶対パスと `repositories` の配列番号を渡し、調査対象のパスを準備する。
1. [list-research-issues.sh](scripts/list-research-issues.sh) に設定ファイルの絶対パスを渡し、追加調査の対象となるオープンな Issue を取得する。
1. `maxOpenIssues` が指定されている場合は、[上限確認フック](../../hooks/check-research-issues.sh) に設定ファイルの絶対パスを渡して実行する。
   終了コードが 2 の場合は新規候補の調査を起動しない。
   件数を取得できない場合は理由を返して終了する。
1. 新規候補の調査と、Issue ごとの追加調査をそれぞれサブエージェントの research に依頼する。
   各実行には調査の種類、設定パスと準備したリポジトリのパスを渡し、追加調査には対象 Issue の URL も渡す。
   新規候補の調査は同時に1件、追加調査は `additionalResearch.concurrency` 件まで実行する。
   両方の合計は research の `concurrency` 件までとし、同じ Issue を並行して調査しない。
1. research 以外の実行予定時刻になったスキルをサブエージェントに実行させる。
   `factory.json` が必要なスキルには、その絶対パスを渡す。
1. すべてのスキルについて、全体とスキルごとの同時処理数の上限に従う。
   全体またはスキルごとの同時処理数が上限に達している場合は、空きができた時点で起動する。
   次の実行予定時刻はスキルの起動時刻に実行間隔を加えた時刻とする。
   research は調査の組を開始した時刻を使う。
   同じコメントには並行して返信しない。
   同じタスクは並行して実装しない。
1. research から候補の一覧または既存 Issue の追加調査結果を受け取ったら、対象ごとに [review-issue スキル](../review-issue/SKILL.md)をサブエージェントに実行させる。
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
   research の次の実行時に上限を再確認する。
1. サブエージェントの完了後に結果を受け取り、上限による見送り以外で保留または失敗した場合は理由を返して終了する。
1. 次の実行予定時刻または実行中のスキルの完了を待ち、停止を求められるまで処理を繰り返す。
