---
name: plan
description: >-
  factory で人間が採用したアイデアを合意内容に沿ってタスクへ分解し、起票または部分起票から再開するときに使う。
compatibility: Requires CUE and configured adapter skills.
allowed-tools: >-
  Read
  Write
  Skill
  Bash(cue export */skills/init/assets/config.cue *)
---

# Plan

入力は設定の絶対パス、元アイデアの `id` または `url`、実行記録の絶対パスとする。
再開時は同じ実行記録を読む。
実装や成果物の作成、採用の判断は行わない。

## 採用と設定の確認

1. 導入済みスキルのカタログから factory の `init` の実在パスを解決する。
   `init` の CUE 定義と factory の README にある共通契約を読み、次を実行する。

   ```sh
   cue export <factory-dir>/skills/init/assets/config.cue json: /absolute/path/factory.json --out json
   ```

   `<factory-dir>` は解決した factory のディレクトリに置き換える。
   成功時の標準出力にある既定値補完済み JSON だけを使う。
   設定、CUE、必要な入力がなければ `wait`、検証失敗なら `error` で停止する。
2. `roles.ideas` と `roles.tasks` の adapter を `adapters` から選ぶ。
   `builtin` は factory、`external` は指定された `plugin` のカタログから `skill` を解決し、各 SKILL.md を読む。
   プラグインを跨ぐ相対パスや別サービスへの切り替えは使わない。
   指定先とスキルの存在、`role`、`target.kind`、必要な `operation` への対応を確認する。
   未対応や解決不能なら `wait` を返す。
3. アダプターへ設定パス、`role`、設定の `target`、`operation`、`input` を渡す。
   `ideas.get` と `ideas.decision` で最新の本文、状態、人間の採用根拠と合意内容を取得する。
   根拠は発言者、日時、対象の版を確認し、状態名だけで採用を決めない。
   取消、未採用、根拠不足、合意の不明点があれば `wait` を返す。
   `tasks.list/get` で元アイデアに対応する既存タスクと実行記録の参照を照合する。

## 分解と起票

1. 合意済みの範囲を調査、設計、実装の必要なタスクに分け、[タスク本文](assets/task.md)を埋める。
   `work` は後続スキルに対応する `research | design | implement` とする。
   各タスクに範囲、受け入れ条件、成果物と保管先を記し、未合意の作業は追加しない。
2. 各タスクの `output` は合意内容に明示された `outputs` のキーを1つだけ使い、解決した adapter と target も記録する。
   未指定、不明なキー、複数指定、受け入れ条件との矛盾は `wait` とし、`repositories` から推測しない。
   複数リポジトリのアイデアは合意に沿って出力先ごとに分け、`change` は1タスクにつき1リポジトリの1 PRとする。
   出力先のアダプターも存在と役割、種類、後続の必要操作への対応を確認し、未対応なら保留する。
   記録済みの出力先や成果物と設定先が異なる場合も `wait` とする。
3. 元アイデアの正本 ID と合意済み作業単位から安定した `key` を決め、起票前に分割案とともに実行記録へ保存する。
   順番や実行日時で key を作り直さず、本文にも `factory-key: <key>` を保持する。
   親子関係の `parentId` と実行順の `blockedBy/blocks` は別々に決め、循環や未合意の依存を追加しない。
   元アイデアの参照を親子関係だけで代用しない。
4. 同じアイデアの起票を直列に行い、各作成の直前に `ideas.get/decision` で採用と合意内容を再確認する。
   取消や合意の変更があれば残りを `wait` とし、作成済みタスクは削除しない。
   確認済み ID は `tasks.get` で優先照合し、ID がなければアダプターの全件照合で key を探す。
   完全一致が1件なら再利用し、複数一致や内容の不一致、書き込み結果不明なら再送せず `wait` とする。
5. 未作成と確定した key だけを `tasks.create` に渡す。
   呼び出し前に key を結果未確認として実行記録へ保存し、中断や応答不明の key は未作成として扱わない。
   依頼に `key` とタスク本文、元アイデア、output、親と依存を含め、親や依存先の確認済み ID を使う。
   参照先を先に起票し、必要な関係更新は `tasks.update` に期待する `revision` と別の安定 key を渡す。
   保存後に `tasks.get` で本文、output、親と依存を確認し、成功した key と `id/url/revision` を次の起票前に実行記録へ保存する。
   部分失敗や結果不明では確認済み ID を残し、未作成と確定した残りだけを再開する。

## 結果

`status: success | wait | error`、確認済みの `items`、`reason`、未完了の `remainingKeys` と実行記録のパスを返す。
`items` に key、元アイデアとタスクの `id/url/revision`、work、output と解決先、成果物参照、親と依存を含める。
成果物は既存の `id/url/revision` を保持し、未作成の値を推測しない。
一部成功や結果不明を `success` にせず、再開に必要な不足と確認済み参照を返す。
