---
name: adapter-linear-comment
description: >-
  Linear Issue のコメントを取得し、トップレベルコメントを保存するときに使う。
compatibility: Requires CUE and the existing connected MCP tools.
allowed-tools: >-
  Read Bash(cue export */skills/init/assets/config.cue *) mcp__codex_apps__linear_get_issue mcp__codex_apps__linear_list_comments mcp__codex_apps__linear_save_comment
---

## 入力

| 入力と対応 | 内容 |
| --- | --- |
| 共通入力 | config/binding/role/output/target/operation/input/key を受け取り、期待参照と current/inventory は input に保持する。 |
| 操作 | comment の staging/artifacts は get/save とし、親 adapter の comments/comment も受け取る。 |
| 親参照 | target.subject または親 adapter から受けた subject の id/url/revision と role を使う。 |
| get/comments | linear_get_issue(id) で親を確認し、linear_list_comments(issueId,cursor) の全ページから指定 id を選ぶ。 |
| save/comment | linear_save_comment は新規に issueId/body、更新に id/body を渡す。 |
| 項目対応 | id/updatedAt/body/author/onBehalfOf/createdAt/parentId を id/revision/body/author/on_behalf_of/created_at/parent_id として返す。 |
| 参照と種類 | url がなければ確認済み Issue URL と comment_id を組にし、root_id と quotedText による種類を保持する。 |
| 依存 | 表の短名は接続中の mcp__codex_apps__ 接頭辞の実ツールと署名を確認し、[結果テンプレート](assets/result.md)を使う。 |

## 出力

status/complete/binding/items を返し、items の id/url/revision/body と確認済み項目を保持する。
未確定の key は省略し、metadata の復元と決定論的な照合は呼び出し元の worker に渡す。

## 制約

トップレベルコメントだけを書き込み、同期スレッドと返信形式は wait とする。
代理投稿を人間本人の判断と推測しない。
取得した id/url と repo または team を入力参照に照合し、更新時は input.expected の revision と一致することを確かめる。
版不一致、取得不足、重複 key、結果不明は wait とし、不明な書き込みを再送しない。
本文を保持し、merge、ready 化、公開、新認証を扱わず、秘密を保存しない。

## 手順

1. `cue export <factory-dir>/skills/init/assets/config.cue json: <config> --out json` の標準出力で binding を照合し、同じ output の role だけの違いを許容する。
   CUE 不在は wait、不正な設定は error とする。
2. hasNextPage=true の間は cursor で続け、書き込み前後に親とコメントの所属、版、本文を確認する。
3. worker の照合後に表の既存 MCP を直接呼び、書き込み後は再取得し、確認済み参照を残して結果を返す。
