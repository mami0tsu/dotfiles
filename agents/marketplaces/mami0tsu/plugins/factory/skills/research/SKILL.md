---
name: research
description: >-
  リポジトリの定期調査、登録済みアイデアの調査、調査タスクを依頼されたときに使う。
  対象の版と範囲を確かめ、ケースに応じた結果と根拠を設定の出力先へ記録する。
compatibility: Requires CUE and configured adapter skills.
allowed-tools: >-
  Read
  Write
  AskUserQuestion
  Bash(cue export */skills/init/assets/config.cue *)
  Bash(git -C * rev-parse *)
  Bash(git -C * show *)
  Bash(git -C * ls-tree *)
---

# Research

## 入力と開始条件

設定の絶対パス、開始理由、アイデアまたは調査タスクの参照、対象の版と範囲、前回の結果を受け取る。
定期調査では前回の完了時刻、アイデア調査では調べたい問い、調査タスクでは受け入れ条件と単一の `output` を確認する。
実装、採用の判断、タスク分割は扱わない。

## 設定と対象の確認

1. 開始時に次を直接実行し、標準出力の既定値補完済み JSON を使う。
   `<init-dir>` は同じプラグインの `skills/init` に置き換える。

   ```sh
   cue export <init-dir>/assets/config.cue json: /absolute/path/factory.json --out json
   ```

   不正な設定なら `error` で停止する。
   設定や CUE がなければ、不足項目を返して `wait` とする。
2. ケースで使用する `roles.ideas`、`roles.tasks`、選んだ `outputs` の binding から `adapters` を引く。
   `source: builtin` は factory、`external` は `plugin` が指定する提供元として、導入済みスキル一覧から `skill` を解決する。
   プラグインをまたぐ相対パスは使わない。
   必要なスキルを読み、役割、`target.kind`、操作への対応と利用可能な実操作を確認する。
   不在、未対応、権限不足なら `wait` とし、別のアダプターへ切り替えない。
3. アイデアは `ideas/collection:get`、タスクは `tasks/collection:get` で正本を取得する。
   `role`、設定の `target`、`operation`、`input` を渡し、入力の参照と結果の `id`、`url` を照合する。
   取得結果が `wait` または `error` なら引き継ぐ。
   調査タスクは現在の状態を `states.tasks.ready` と照合する。
   状態不一致、未解消の依存、取消、着手可否が不明の場合は保留する。
   アイデア調査は登録後に実施でき、採用済みであることは要求しない。
4. 次の表からケースを1つ選び、対象 repository、revision、paths と問いを確定する。
   複数ケースに当てはまる場合や根拠が足りない場合は、選択に必要な入力を返して保留する。

| ケース | 開始条件と調査内容 |
| --- | --- |
| 定期調査 | 定期実行の依頼で、前回の完了時刻から `research.intervalSeconds` が経過している場合に `repositories` の各対象を調べる。初回は初回と記録する。期限前は次回時刻を返して `wait` とする。コードや文書からアイデア候補と根拠をまとめ、候補がなければその結果を記録する。 |
| アイデア調査 | 登録済みアイデアについて調査を依頼された場合に、問いに対する実現方法、制約、未解決事項をまとめる。対象 repository と範囲は依頼またはアイデアの明示情報から確認する。 |
| 調査タスク | 調査を成果とするタスクについて、受け入れ条件に対応する結論と成果物を作る。条件を満たさない部分は未解決事項に残し、満たしたと報告しない。 |

新規開発で repository が未定なら、未定である根拠と不足情報を返す。
repository が必要な調査は `wait` とし、repository に依存しない問いが明示されていれば、その範囲だけを調べる。
`repositories` を管理先や記録先として流用しない。
定期調査で対象が空なら保留する。

## 調査と記録

1. 明示された対象を読み、可変の ref は取得時の commit 等の固定 revision に解決する。
   ローカルでは `git -C <repo> rev-parse <ref>^{commit}`、`ls-tree`、`show` で版と範囲を照合する。
   リモート取得は導入済みスキルの実在する読み取り手順とツールを使う。
   取得できない対象は推測で補わず保留する。
   根拠には出典 URL または path と固定 revision を添え、確認した事実と推測を区別する。
2. 記録には `outputs` のキーを1つ使う。
   調査タスクはタスクの単一 `output` を維持する。
   未指定、複数値、未知のキー、受け入れ条件との矛盾は `wait` とする。
   定期調査とアイデア調査もキーを確認し、出力先が複数あれば明示選択を求める。
   出力先が1つの場合はそのキーを記録する。
3. 記録済みの出力先、対象 repository、成果物の `id`、`url`、`revision` を照合する。
   同じキーの `target` が変わるなど、過去の参照と一致しなければ `wait` とする。
   コメントの `subject` は現在のアイデア、タスク、固定 URL から解決し、対象の `id` と `url` を `input` に渡す。
   定期調査に現在のアイデアやタスクがなければ、その対象を要求するコメント先は使えない。
4. [出力テンプレート](assets/result.md)に結果をまとめ、選んだ binding へ `role: staging`、`operation: save` を依頼する。
   `target` は設定の値をそのまま渡し、保存内容、対象参照、既存の成果物参照を `input` に含める。
   更新には対象と調査回を識別する安定した `key` を使い、同じ調査の再開時には引き継ぐ。
   既存の成果物参照があれば、保存前に同じ binding の `staging/get` で内容と版を照合する。
   新規なら参照のない `get` を要求せず、安定した `key` を渡してアダプターの保存前の重複確認に従う。
   同じ結果は再利用する。
   同一対象の更新は直列化し、結果不明の書き込みは再送せず保留する。
5. 保存後に同じアダプターで再取得し、内容と `id`、`url`、`revision` を確認して返す。
   参照や版が不足する場合は保留する。
   アイデア、タスク、`output`、解決済み `target`、成果物の対応を次のレビューへ引き継ぐ。
   `status: success | wait | error`、`items`、`reason` を返し、保留時は不足入力と再開位置を示す。
   定期調査は保存確認後の完了時刻を返し、保留を完了として扱わない。
   候補の登録や採用、タスクの状態変更は行わない。
