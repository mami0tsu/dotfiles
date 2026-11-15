---
name: adapter-github-file
description: >-
  GitHub の明示した版のファイルを取得し、作業ブランチへ保存するときに使う。
compatibility: Requires CUE and the existing connected MCP tools.
allowed-tools: >-
  Read Bash(cue export */skills/init/assets/config.cue *) mcp__codex_apps__github_get_repo mcp__codex_apps__github_fetch mcp__codex_apps__github_fetch_file mcp__codex_apps__github_create_file mcp__codex_apps__github_update_file
---

## 入力

| 入力と対応 | 内容 |
| --- | --- |
| 共通入力 | config/binding/role/output/target/operation/input/key を受け取り、期待参照と current/inventory は input に保持する。 |
| 操作 | file の staging/artifacts で get/save を扱う。 |
| 対象解決 | github_get_repo の repository_id/repository_url から repository_full_name を得て、target.path を使う。 |
| get | github_fetch_file(repository_full_name,path,ref) へ明示した Git ref を渡す。 |
| save | github_create_file と github_update_file は repository_full_name/path/branch/content/message を使い、更新時だけ sha を渡す。 |
| 不在確認 | github_fetch(url) で https://api.github.com/repos/{repo}/contents/{parent}?ref={branch} の完全な一覧を取得する。 |
| 項目対応 | content/sha を body/revision とし、正本の id/url は同じ path で維持する。 |
| 保存後の参照 | commit_sha で再取得し、commit/read_ref と保存先の write_ref、実際の read_url を保持する。 |
| 依存 | 表の短名は接続中の mcp__codex_apps__ 接頭辞の実ツールと署名を確認し、[結果テンプレート](assets/result.md)を使う。 |

## 出力

status/complete/binding/items を返し、items の id/url/revision/body と確認済み項目を保持する。
未確定の key は省略し、metadata の復元と決定論的な照合は呼び出し元の worker に渡す。

## 制約

保存先 branch を明示し、期待する blob SHA を更新の sha に使う。
blob SHA を Git ref と扱わず、読み返しには固定した commit を使う。
取得した id/url と repo または team を入力参照に照合し、更新時は input.expected の revision と一致することを確かめる。
版不一致、取得不足、重複 key、結果不明は wait とし、不明な書き込みを再送しない。
本文を保持し、merge、ready 化、公開、新認証を扱わず、秘密を保存しない。

## 手順

1. `cue export <factory-dir>/skills/init/assets/config.cue json: <config> --out json` の標準出力で binding を照合し、同じ output の role だけの違いを許容する。
   CUE 不在は wait、不正な設定は error とする。
2. worker が渡した本文と metadata を保持し、commit message には key を残す。
3. worker の照合後に表の既存 MCP を直接呼び、書き込み後は再取得し、確認済み参照を残して結果を返す。
