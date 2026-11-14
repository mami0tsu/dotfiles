---
name: linear
description: >-
  factory から Linear のアイデアとタスクを管理し、コメントとして成果物を読み書きするときに使う。
compatibility: Requires CUE, the dev plugin, and connected Linear tools.
allowed-tools: >-
  Read
  Bash(cue export */skills/init/assets/config.cue *)
  mcp__codex_apps__linear_whoami
  mcp__codex_apps__linear_get_team
  mcp__codex_apps__linear_get_user
  mcp__codex_apps__linear_list_issue_statuses
  mcp__codex_apps__linear_list_issues
  mcp__codex_apps__linear_get_issue
  mcp__codex_apps__linear_save_issue
  mcp__codex_apps__linear_list_comments
  mcp__codex_apps__linear_save_comment
---

# Linear

## 入力と対応操作

設定の絶対パス、`role`、`target`、`operation`、`input`、書き込みには安定した `key` を受け取る。
`input` は取得対象の正本 `id` または `url`、既存コメントの `commentId`、期待する `revision`、操作に必要な本文や変更値を持つ。
解決後は対象の `id` と `url` を両方引き継ぐ。
元アイデア、親、依存先、選択した `output` キー、成果物の `id`、`url`、`revision` も引き継ぐ。

| role | target.kind | operation |
| --- | --- | --- |
| `ideas` | `collection` | `list`, `get`, `create`, `comments`, `comment`, `decision` |
| `tasks` | `collection` | `list`, `get`, `create`, `update`, `comment` |
| `staging`, `artifacts` | `comment` | `get`, `save` |

この表以外の組み合わせ、`file`、`change`、プロジェクトを集合とする操作は未対応として `wait` を返す。
別のアダプターへ切り替えない。

## 共通手順

1. 開始時に次を実行し、標準出力の既定値補完済み JSON だけを設定として使う。
   CUE や設定がない場合は `wait`、検証が失敗した場合は `error` を返す。

   ```sh
   cue export <factory-dir>/skills/init/assets/config.cue json: /absolute/path/factory.json --out json
   ```

2. `ideas` と `tasks` は設定の同名 role と照合する。
   `staging` と `artifacts` はタスクが選んだ1つの `outputs[input.output]` と照合する。
   未指定、不明、複数の output や、記録済み対象と設定の不一致は `wait` を返す。
3. [linear-usage](../../../dev/skills/linear-usage/SKILL.md) と [ticket contract](../../../dev/skills/ticket-usage/references/contract.md) を読み、ID 解決、親子と依存の更新、更新前後の検証を再利用する。
   provider 選択は factory の設定で確定しているため、Git 設定による選択は行わない。
   接続中の Linear ツールのスキーマと権限を確認し、必要な操作が使えなければ不足を示して `wait` を返す。
   以下は操作名の末尾だけを記し、frontmatter は確認済み接続のツール名を示す。
   クライアントで prefix が異なる場合も、同じ Linear 接続の実在ツールと入力スキーマを照合し、対応を確認できなければ `wait` を返す。
4. `collection` の `target.container` はチームの正本 ID、または `https://linear.app/<workspace>/team/<key>/all` を受け取る。
   URL は `whoami` の workspace URL と一致する場合だけ key を取り出し、`get_team(query)` で実在を確認して返された ID を `team` に使う。
   ID 入力は返された `id`、URL 入力は返された `key` との完全一致も確認する。
   URL の別形式、曖昧な ID、チームとして解決できない対象は推測せず `wait` を返す。
   取得する issue は `teamId` も照合し、別チームの対象は操作しない。
5. `comment` の `target.subject` は呼び出し元が解決した現在のアイデアかタスク、または固定 URL と `input.id`、`input.url` の一致を確認する。
   初期対応は issue のコメントだけとし、`linear-usage` の URL 規則で `get_issue(includeRelations: true)` に変換する。
   固定 URL が別の種類の対象を指す場合は `wait` を返す。
   ファイルの `path` は要求しない。

## collection のケース

- `list` は `list_issues(team)` を使い、`hasNextPage` が true の間は返された `cursor` で続ける。
  `fields` に `teamId` を含め、対象チームと完全一致する issue だけを返す。
  一覧の description は省略される場合があるため、本文の判定には `get_issue(includeRelations: true)` を使う。
- `get` は `get_issue(includeRelations: true)` を使い、`updatedAt`、`teamId`、`parentId`、`relations` と正本 URL を取得する。
- `create` と `tasks.update` は `save_issue` を使い、作成時は解決済みの `team` と `title`、更新時は `id` を渡す。
  担当者は `get_user` で解決して `assignee` に渡す。
  状態の指定前は `list_issue_statuses(team)` で実在を確認し、承認範囲内の変更値だけを書く。
  `parentId`、`blockedBy`、`blocks` は別々の関係として同じ作成呼び出しへ渡し、更新では取得済み集合との差分だけを指定する。
  元アイデア、output、成果物参照は description に保持し、既存本文を置換するときも消さない。
  1タスクには output キーを1つだけ記録し、変更提案の場合は1リポジトリの1 PRに対応するか確認する。
- `ideas.comments` と両 role の `comment` は下記のコメント手順で、それぞれ一覧を取得し、保存する。
- `ideas.decision` は issue の状態と `stateHistory`、必要ならコメントを読み、人間の採用か取消の根拠を返す読み取り操作とする。
  `states.ideas.adopted` と `withdrawn`、タスクの `states.tasks.ready` と `release-ready` は実在する状態名と照合する。
  人間の判断は発言者、日時、対象の版を確認できる記録と照合し、状態名だけで採用、取消、承認、リリース可能を決めない。
  根拠を取得できない場合は `wait` を返し、人間の判断を作る状態更新は行わない。

## コメントのケース

`ideas.comments` と `staging/artifacts.get` は `list_comments(issueId: <解決済みissue ID>)` を全ページ取得する。
`get` は `input.commentId` の完全一致で選び、取得結果からコメント ID、本文、作成者、更新日時を返す。
`revision` は取得したコメントの `updatedAt` とし、取得できなければ版を確認できないため `wait` を返す。
`url` はツールが返すコメント URL を使い、なければ確認済みの issue URL と `commentId` を対で返す。

`comment` と `save` は `save_comment` を使う。
新規は `issueId` と `body`、更新は `id: input.commentId` と `body` を渡す。
`id` を渡すと親指定は無視されるため、更新前に対象 issue の一覧でその ID の所属を確認する。
本文には実際の改行を渡し、既存の key、元アイデア、output、成果物参照を保持する。
保存後は同じ issue から再取得し、本文、ID、対象、版を照合する。
スレッドへの返信、同期された外部スレッドへの投稿、削除、ファイル添付は初期対応に含めない。

## 再実行と結果

書き込み前に現在値を再取得し、期待する `revision` や関係と異なれば `wait` を返す。
既存の更新で期待する版が不足する場合も `wait` を返す。
issue の `revision` は `updatedAt` とする。
条件付き書き込みは使えないため、直前照合と事後検証でも競合そのものは防げない。

新規本文には `factory-key: <key>` を1行で記録し、同じ対象内の完全一致で再実行を照合する。
記録済み ID があれば優先して取得し、なければチームの issue を `includeArchived: true` で、または対象 issue のコメントを全ページ確認する。
同じ key が一件なら期待値を比較し、同じ内容なら再作成せず、不足する承認済み変更だけを書く。
複数一致や書き込み結果不明は `wait` とし、照合して確定するまで再起票や再投稿をしない。
部分起票では確認済みの各 key と ID を返して呼び出し元に記録させ、未作成と確定した残りの key だけを再開対象とする。

[結果テンプレート](assets/result.md)で `success | wait | error`、確認済みの項目、理由、未完了の key を返す。
各項目には正本 `id` と `url`、状態、`revision`、コメントなら `commentId`、追跡用の key と参照を含める。
書き込みの一部成功や結果不明を `success` とせず、成功分の識別子を残して `wait` を返す。
