---
name: adapter-github-pr
description: >-
  GitHub の変更提案を Draft PR として作成し、取得と更新を行うときに使う。
compatibility: Requires CUE and the existing connected MCP tools.
allowed-tools: >-
  Read Bash(cue export */skills/init/assets/config.cue *) mcp__codex_apps__github_get_repo mcp__codex_apps__github_fetch mcp__codex_apps__github_create_pull_request mcp__codex_apps__github_update_pull_request mcp__codex_apps__github_request_pull_request_reviewers
---

## 入力

| 入力と対応 | 内容 |
| --- | --- |
| 共通入力 | config/binding/role/output/target/operation/input/key を受け取り、期待参照と current/inventory は input に保持する。 |
| 操作 | change の staging/artifacts は get/save、changes は get/create/comments/comment/request-review を扱う。 |
| 対象解決 | github_get_repo の repository_id/repository_url から repository_full_name を得る。 |
| get/既存候補 | github_fetch(url) で https://api.github.com/repos/{repo}/pulls/{number} または `/pulls?state=all&per_page=100&page=N` を取得する。 |
| create/save | github_create_pull_request は repository_full_name/base/head/title/body/draft:true、既存は github_update_pull_request の pr_number/title/body を使う。 |
| 項目対応 | id/html_url/head.sha/body と base.ref/head.ref を id/url/revision/body と base/head に対応させる。 |
| comments/comment | [コメント用スキル](../adapter-github-comment/SKILL.md)へ同じ binding と解決済み PR 参照を渡す。 |
| request-review | config.reviewers の実在 login を github_request_pull_request_reviewers(repository_full_name,pr_number,reviewers)へ渡す。 |
| 依存 | 表の短名は接続中の mcp__codex_apps__ 接頭辞の実ツールと署名を確認し、[結果テンプレート](assets/result.md)を使う。 |

## 出力

status/complete/binding/items を返し、items の id/url/revision/body と確認済み項目を保持する。
未確定の key は省略し、metadata の復元と決定論的な照合は呼び出し元の worker に渡す。

## 制約

1タスク1リポジトリ1 PR を守り、明示した base/head/SHA を照合する。
Draft の正式レビュー依頼は人間待ちとし、レビュー依頼を人間の承認と扱わない。
取得した id/url と repo または team を入力参照に照合し、更新時は input.expected の revision と一致することを確かめる。
版不一致、取得不足、重複 key、結果不明は wait とし、不明な書き込みを再送しない。
本文を保持し、merge、ready 化、公開、新認証を扱わず、秘密を保存しない。

## 手順

1. `cue export <factory-dir>/skills/init/assets/config.cue json: <config> --out json` の標準出力で binding を照合し、同じ output の role だけの違いを許容する。
   CUE 不在は wait、不正な設定は error とする。
2. 新規作成前は全状態の PR を全ページ取得し、既存 key とタスク参照を worker へ返す。
3. worker の照合後に表の既存 MCP を直接呼び、書き込み後は再取得し、確認済み参照を残して結果を返す。
