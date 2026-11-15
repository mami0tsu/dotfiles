---
name: adapter-linear-issue
description: >-
  Linear Issue の集合を取得し、タスクの起票と更新を行うときに使う。
compatibility: Requires Python 3, CUE, and the existing connected MCP tools.
allowed-tools: >-
  Read Bash(python3 */scripts/*.py *) mcp__codex_apps__linear_list_issues mcp__codex_apps__linear_get_issue mcp__codex_apps__linear_save_issue mcp__codex_apps__linear_list_comments mcp__codex_apps__linear_save_comment
---

## 入力

| 依存 | 値 |
| --- | --- |
| 設定 | config は絶対パスとし、role/output/expected_binding を共通 CUE と照合する。 |
| 実行入力 | phase、input、context、response を持つ JSON を渡す。 |
| 操作 | collection の list/get/create/update/decision/comments/comment を使う。 |
| 対象 | 取得には input.id または url を渡し、更新には完全な input.current と期待する input.expected を渡す。 |
| 本文 | input.body/title と key を渡し、作成には完全な input.inventory、関係変更には input.relations を渡す。 |
| MCP 対応 | tools は確認済みの短名から実ツール名への対応表とし、引数の署名も実接続で確認する。 |
| スクリプト | [操作別スクリプト](scripts/)と[共通処理](../../scripts/common.py)、[MCP 橋渡し](../../scripts/mcp.py)、[provider 処理](../../scripts/providers/)を使う。 |
| 結果 | [結果テンプレート](assets/result.md)を使う。 |

## 出力

status、complete、binding、items の id/url/revision/key を返す。
未完了なら call/context または reason を返し、確認済み参照を引き継ぐ。

## 制約

team UUID を指定し、チーム URL には実接続の workspace_response と team_response を渡す。
人間の判断は原文と発言者を確認して読むだけとし、状態名や AI の記述から採用を決めない。
版不一致、ページ不足、複数の key 一致、結果不明は保留し、結果不明の書き込みを再送しない。
新しい SDK、直 API 認証、秘密の保存、merge、ready 化、公開は追加しない。

## 手順

1. スキルのディレクトリで `python3 scripts/{operation}.py --input request.json` を phase=prepare で実行する。
2. 出力された call の実在 MCP だけを呼び、元の設定と context を保持して生の結果を response に渡す。
3. 同じスクリプトを phase=normalize で実行し、次の call があれば同じ手順で取得と事後検証を続ける。
4. complete=true の結果だけを完了として返し、書き込みは同じ対象ごとに直列化する。
