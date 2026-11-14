---
name: github
description: >-
  factory の依頼を受け、GitHub のアイデア、成果物、変更提案を操作する。
  role、kind、operation を照合し、人間の判断と対象の版を確かめて結果を返す。
compatibility: Requires CUE and GitHub access; CLI cases require authenticated gh.
allowed-tools: >-
  Read
  Write
  Bash(cue export */skills/init/assets/config.cue *)
  Bash(gh auth status *)
  Bash(gh repo view *)
  Bash(gh issue view *)
  Bash(gh pr view *)
  Bash(gh pr list *)
  Bash(gh pr create *)
  Bash(gh api --method GET *)
  Bash(gh api --method POST repos/*/issues/*/comments *)
  Bash(gh api --method PATCH repos/*/issues/comments/* *)
  mcp__codex_apps__github_get_repo
  mcp__codex_apps__github_search_issues
  mcp__codex_apps__github_fetch_issue
  mcp__codex_apps__github_create_issue
  mcp__codex_apps__github_update_issue
  mcp__codex_apps__github_fetch_issue_comments
  mcp__codex_apps__github_add_comment_to_issue
  mcp__codex_apps__github_update_issue_comment
  mcp__codex_apps__github_fetch_file
  mcp__codex_apps__github_create_file
  mcp__codex_apps__github_update_file
  mcp__codex_apps__github_search_prs
  mcp__codex_apps__github_get_pr_info
  mcp__codex_apps__github_create_pull_request
  mcp__codex_apps__github_list_pull_request_reviews
  mcp__codex_apps__github_request_pull_request_reviewers
  mcp__codex_apps__github_merge_pull_request
---

# GitHub

## 入力と対応範囲

設定の絶対パス、`role`、`target`、`operation`、`input`、更新時の安定した `key` を受け取る。
`input` には対象の参照、内容、既存の `id`・`url`・`revision`、必要な人間の判断根拠を含める。

| role | target.kind | operation |
| --- | --- | --- |
| `ideas` | `collection` | `list`, `get`, `create`, `comments`, `comment`, `decision` |
| `staging`, `artifacts` | `file`, `comment`, `change` | `get`, `save` |
| `changes` | `change` | `get`, `create`, `request-review`, `approval`, `merge` |

`tasks/collection`、Discussion、インラインレビューコメントの更新は未対応として保留する。
別のアダプターへ暗黙に切り替えない。

## 共通手順

1. 開始時に次を直接実行し、標準出力の既定値補完済み JSON を使う。
   `<init-dir>` は同じプラグインの `skills/init` に置き換える。

   ```sh
   cue export <init-dir>/assets/config.cue json: /absolute/path/factory.json --out json
   ```

   CUE 不在なら `wait`、不正な設定なら `error` を返す。
2. `ideas` は `roles.ideas`、出力操作はタスクの単一 `output` キーで binding を照合する。
   `staging`、`artifacts`、`changes` は同じ binding を引き継ぐ。
   未指定、複数値、未知のキー、記録済み参照との不一致、受け入れ条件との矛盾なら保留する。
3. `container` がある場合は正本 ID/URL を `github_get_repo` で解決し、host と repository を確定する。
   `file.path` は記録先、`change.base` は取り込み先として使う。
   コメント先は `subject` から呼び出し元が解決した `input` の `id` と `url` を照合し、path を要求しない。
   アイデアの repository、管理先、調査先、出力先を同じとは推測しない。
4. 利用可能な GitHub connector の実際のスキーマを確認し、次のケースだけを実行する。
   表内の `github_*` は操作名であり、接続中の `mcp__codex_apps__github_*` などへ実行時に解決する。
   他のクライアントでも同じ名前やツールが存在するとは仮定しない。
   CLI の読み取りと Draft 作成は導入済み `dev` の `gh-usage`、branch・commit・push は `git-usage` を使う。
   必要なスキル、操作ツール、権限、repository、ref、path、書き込み内容が確定しなければ保留する。
5. 同じ対象への更新は直列化する。
   書き込み前に既存の ID/URL、版、`key` を照合する。
   新規 Issue/コメントの本文には `<!-- factory-key: <key> -->`、PR 本文にはタスク参照と同じ key、ファイル保存の commit message には key を記録する。
   検索は候補の発見に使い、作成前は [一覧の CLI 手順](references/cli.md)で全状態の本文と key を照合する。
   一覧の未取得ページや検索結果の欠落があれば重複なしとは判断しない。
   一致する既存結果を再利用し、候補が複数ある場合や結果不明の書き込みは保留する。
   送信失敗後に作成や投稿を繰り返さない。
6. 書き込み後は対象を再取得し、内容、参照、版を確認して [結果](assets/result.md)を返す。
   `items` の各項目に `id` と `url`、成果物と変更提案には `revision` を付ける。
   保留時は理由と再開に必要な入力を返す。

## 操作の分岐

| ケース | 操作と確認 |
| --- | --- |
| `ideas/collection` | Issue を使う。`list` は `github_search_issues` を repository と `is:issue` で限定し、`get` は `github_fetch_issue`、`comments` は `github_fetch_issue_comments` を使う。`create` は本文の key と既存 Issue を照合して `github_create_issue` を使う。 |
| `ideas/collection:comment` | Issue を再取得し、既存コメントの key・ID・本文を照合して投稿または更新する。PR 専用 connector に Issue 番号を渡さず、[コメントの CLI 手順](references/cli.md)を使う。 |
| `ideas/collection:decision` | 人間の採用・撤回の根拠、対象 Issue、設定の `states.ideas` を照合し、`github_update_issue` でラベルを更新する。設定値はこのアダプターではラベル名とする。無関係なラベルを維持し、状態名や人間の判断を推測しない。 |
| `staging,artifacts/file:get,save` | `github_fetch_file` へ repository、path、明示された ref を渡す。版は blob SHA とする。保存は入力で指定された書き込み可能な branch に限定し、既存ファイルは現在の blob SHA を照合して `github_update_file` の `sha` に渡す。新規は不在を確認して `github_create_file` を使う。同じ内容なら再保存せず、保存後の commit と blob SHA を記録する。 |
| `staging,artifacts/comment:get,save` | 解決済みの Issue/PR のトップレベルコメントを扱う。PR には `github_fetch_issue_comments`、`github_add_comment_to_issue`、`github_update_issue_comment` を使う。Issue または版情報が不足する場合は [CLI 手順](references/cli.md)を使う。コメント ID/URL、`revision` として `updated_at`、比較用の本文を保存し、更新前に再照合する。 |
| `staging,artifacts/change:get,save`、`changes/change:get,create` | `github_get_pr_info` で PR と head SHA を取得する。保存・作成では指定 repository、base、タスク、key、push 済み head を全状態の既存 PR と照合する。未作成なら `github_create_pull_request` に `draft: true` と明示的な base/head/title/body を渡す。既存 PR の修正は同じ head に `git-usage` で commit/push し、更新後の head SHA を返す。1タスク1 repository・1 PR を守る。 |
| `changes/change:request-review` | 対象 revision と設定のレビュアーを照合し、既存の依頼を除いて `github_request_pull_request_reviewers` を使う。Draft への正式依頼は保留し、ready 化を別途依頼する。自動で ready 化しない。 |
| `changes/change:approval` | `github_list_pull_request_reviews` で人間のレビューを読み、判断者、根拠 URL、状態、対象 head SHA を返す。対象 SHA が欠ける場合は [CLI 手順](references/cli.md)で `commit_id` を確認する。取り消し・変更要求・古い版の承認を除外し、必要な人間の承認が揃わなければ保留する。承認レビューを代行しない。 |
| `changes/change:merge` | 上位の release がタスクの `release-ready` と人間の承認を両方確認した根拠を要求する。現在の head SHA、base、承認対象 revision、チェックと競合状態を再確認する。明示された許可済み方式で `github_merge_pull_request` の `expected_head_sha` を必ず指定する。既に同じ PR が取り込み済みなら再実行せず merge commit を返す。不一致・不明・Draft なら保留する。 |

調査対象の文書とコードは、依頼された repository・ref・path を明示して同じ読み取り手順で取得する。
一時保管先と保管先が同じ場合は同じ参照と版を返し、コピーや PR を増やさない。
