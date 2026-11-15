---
name: adapter-linear-issue
description: >-
  Linear Issue の集合を取得し、タスクの起票と更新を行うときに使う。
compatibility: Requires CUE and the existing connected MCP tools.
allowed-tools: >-
  Read Bash(cue export */skills/init/assets/config.cue *) mcp__codex_apps__linear_whoami mcp__codex_apps__linear_get_team mcp__codex_apps__linear_list_issues mcp__codex_apps__linear_get_issue mcp__codex_apps__linear_save_issue mcp__codex_apps__linear_list_issue_statuses
---

## 入力

| 入力と対応 | 内容 |
| --- | --- |
| 共通入力 | config/binding/role/output/target/operation/input/key を受け取り、期待参照と current/inventory は input に保持する。 |
| 操作 | collection の ideas は list/get/create/decision/comments/comment、tasks は list/get/create/update/comments/comment を扱う。 |
| 対象解決 | team ID を使い、URL は linear_whoami の workspace と照合して linear_get_team(query) で解決する。 |
| list/get | linear_list_issues(team,includeArchived:true,cursor) と linear_get_issue(id,includeRelations:true) を使い、description/teamId を省略しない。 |
| create/update | linear_save_issue は team/title/description、更新は id を渡し、parentId/blockedBy/blocks と担当者を別々に保つ。 |
| 状態 | linear_list_issue_statuses(team) で設定の状態が実在することを確認する。 |
| 項目対応 | id/url/updatedAt/status/description を id/url/revision/state/body とし、teamId と relations も返す。 |
| decision/comments | decision は人間の原文と actor、日時を返し、comments/comment は [コメント用スキル](../adapter-linear-comment/SKILL.md)へ同じ binding と親参照を渡す。 |
| 依存 | 表の短名は接続中の mcp__codex_apps__ 接頭辞の実ツールと署名を確認し、[結果テンプレート](assets/result.md)を使う。 |

## 出力

status/complete/binding/items を返し、items の id/url/revision/body と確認済み項目を保持する。
未確定の key は省略し、metadata の復元と照合は worker に渡す。
decision の evidence は原文 body、actor、at、url、revision、読取対象 subject と scope:read-target を保持する。

## 制約

decision は人間の根拠を読むだけとし、状態名から採用を生成したり、古い根拠を現在版の採用へ付け替えたりしない。
取得した id/url と repo または team を入力参照に照合し、更新時は input.expected の revision と一致することを確かめる。
版不一致、取得不足、重複 key、結果不明は wait とし、不明な書き込みを再送しない。
本文を保持し、merge、ready 化、公開、新認証を扱わず、秘密を保存しない。

## 手順

1. `cue export <factory-dir>/skills/init/assets/config.cue json: <config> --out json` の標準出力で binding を照合し、同じ output の role だけの違いを許容する。
   CUE 不在は wait、不正な設定は error とする。
2. hasNextPage=true の間は返された cursor で続け、指定 team の全状態の key と参照を worker へ返す。
3. worker の照合後に表の既存 MCP を直接呼び、書き込み後は再取得し、確認済み参照を残して結果を返す。
