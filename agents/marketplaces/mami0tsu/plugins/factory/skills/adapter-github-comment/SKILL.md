---
name: adapter-github-comment
description: >-
  GitHub のコメントを取得し、PR のトップレベルコメントを保存するときに使う。
compatibility: Requires CUE and the existing connected MCP tools.
allowed-tools: >-
  Read Bash(cue export */skills/init/assets/config.cue *) mcp__codex_apps__github_fetch mcp__codex_apps__github_add_comment_to_issue mcp__codex_apps__github_update_issue_comment
---

## 入力

| 入力と対応 | 内容 |
| --- | --- |
| 共通入力 | config/binding/role/output/target/operation/input/key を受け取り、期待参照と current/inventory は input に保持する。 |
| 操作 | comment の staging/artifacts は get/save とし、親 adapter の comments/comment も受け取る。 |
| 親参照 | target.subject または親 adapter から受けた subject の id/url/revision と role を使う。 |
| get/comments | github_fetch(url) で https://api.github.com/repos/{repo}/issues/{number}/comments?per_page=100&page=N を全ページ取得し、指定 id を選ぶ。 |
| PR の一覧 | /pulls/{number}/comments と /pulls/{number}/reviews も全ページ取得し、Conversation、インライン、レビュー本文を区別する。 |
| save/comment | PR の新規は github_add_comment_to_issue(repo_full_name,pr_number,comment)、更新は github_update_issue_comment(repo_full_name,comment_id,comment) を使う。 |
| 項目対応 | id/html_url/updated_at/body/user/created_at を id/url/revision/body/author/created_at とし、parent_id と root_id を保持する。 |
| 未対応形式 | Issue 投稿、レビュー本文、インライン返信、同期スレッドへの書き込みは wait とする。 |
| 依存 | 表の短名は接続中の mcp__codex_apps__ 接頭辞の実ツールと署名を確認し、[結果テンプレート](assets/result.md)を使う。 |

## 出力

status/complete/binding/items と元の request を返し、items の id/url/revision/body と確認済み項目を保持する。
未確定の key は省略し、metadata の復元と決定論的な照合は呼び出し元の worker に渡す。

## 制約

MCP の PR 専用引数へ Issue 番号を流用せず、返信をトップレベル投稿へ変換しない。
取得した id/url と repo または team を入力参照に照合し、更新時は input.expected の revision と一致することを確かめる。
版不一致、取得不足、重複 key、結果不明は wait とし、不明な書き込みを再送しない。
本文を保持し、merge、ready 化、公開、新認証を扱わず、秘密を保存しない。

## 手順

1. `cue export <factory-dir>/skills/init/assets/config.cue json: <config> --out json` の標準出力で binding を照合し、同じ output の role だけの違いを許容する。
   CUE 不在は wait、不正な設定は error とする。
2. 書き込み前後に親とコメントを再取得し、所属、期待版、本文を worker の検証へ渡す。
3. worker の照合後に表の既存 MCP を直接呼び、書き込み後は再取得し、確認済み参照を残して結果を返す。
