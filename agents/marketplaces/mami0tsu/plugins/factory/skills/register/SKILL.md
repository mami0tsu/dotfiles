---
name: register
description: >-
  factory の AI レビューを通過した候補をアイデアとして登録するときに使う。
  元候補と判定対象の版を照合し、既存アイデアとの対応を残す。
compatibility: Requires CUE and configured adapter skills.
allowed-tools: >-
  Read
  Write
  Skill
  Bash(cue export */skills/init/assets/config.cue *)
---

# Register

## 入力

設定の絶対パス、候補の内容と根拠、review から単一 `output`、AI 判定、`reviewed` と保存後の `record`（それぞれ `id`、`url`、`revision`）を受け取る。
元調査の参照、記録内の候補識別子、候補の `key`、前回の登録結果も引き継ぐ。
コメント記録では `commentId` と親対象の `id`、`url` など、アダプターの取得に必要な参照も保持する。
未登録候補のアイデアやタスクの ID、人間の採用は要求しない。
採用、タスク起票、候補の修正は扱わない。

## 手順

1. 導入済みスキルのカタログから factory の `init` の実パスを解決し、次を直接実行する。
   標準出力の既定値補完済み JSON を使い、CUE や設定の不在は `wait`、設定不正は `error` とする。

   ```sh
   cue export <init-dir>/assets/config.cue json: /absolute/path/factory.json --out json
   ```

2. 登録先には `roles.ideas`、候補記録には research と review から引き継いだ `outputs[output]` を使う。
   `output` が未指定、複数値、未知のキーなら保留する。
   同名キーの設定先を含め、記録済みの操作先、リポジトリ、対象の参照と一致しなければ保留する。
   各 binding の `adapter` を `adapters` で引き、`source: builtin` は factory、`external` は指定 `plugin` の `skill` をカタログから解決する。
   実パスの SKILL.md を読み、役割、`target.kind`、必要な操作、ツールと権限への対応を確認する。
   プラグインをまたぐ相対パスやサービス名の分岐を使わず、不在や未対応なら保留する。
   各依頼には設定パス、`role`、設定の `target`、`operation`、`input`、書き込みには安定した `key` を渡す。
3. 同じ出力先の `staging/get` で `record` を読み、元候補、根拠、AI 判定の参照と対象版を照合する。
   AI `pass` は `reviewed` 版の候補内容だけに適用する。
   レビュー追記で版が変わった場合は、固定した旧版の取得など、アダプターが対応する方法で `reviewed` と `record` の候補内容と根拠の一致を確認する。
   新しい候補内容への判定流用、旧版の取得不能、対応不明、`pass` 以外、参照や版の不足は `wait` とし、修正や再レビューの条件を返す。
4. 候補ごとに同じ `key` を使う。
   未設定なら元調査の固定参照と記録内の候補識別子から決め、以後のレビュー追記や再開でも保持する。
   候補を一意に識別できなければ保留し、実行日時や現在の記録版から別の key を作らない。
   `ideas/list` で登録先のアーカイブを含む全件を取得し、必要な本文は `ideas/get` で読む。
   記録済みのアイデア ID、key、元候補の参照、内容と根拠を照合し、意味の重なる既存アイデアも確認する。
   取得範囲が不足すれば保留する。
5. 同じ key の登録が1件あり内容も一致すれば、作成せずその `id` と `url` を再利用する。
   別 key でも同じ候補や重複アイデアなら新規登録せず、既存対象と登録しなかった理由を返す。
   複数一致、内容の食い違い、重複か判断できない場合は `wait` とし、既存本文を上書きしない。
6. 未登録と確認できた候補だけを `ideas/create` へ渡す。
   本文に候補内容、根拠、元候補の参照、`output` と操作先、`reviewed`、AI 判定の理由と `record`、key を残す。
   `states.ideas.adopted` を指定せず、人間の採用を自動設定しない。
   同じ候補への書き込みを直列化し、直前に記録の版と既存登録を再照合する。
   変化があれば手順3へ戻り、条件付き作成がない場合の並行実行による競合は防げると扱わない。
7. 登録先の `ideas/get` で保存結果を読み返し、内容、参照、key、`id`、`url` を確認する。
   結果不明の書き込みは繰り返さず `wait` とし、再開時に手順4から照合する。
   複数候補の一部だけ成功した場合も、確認済みの key と ID、未完了の key を分けて保留する。
   再開では成功分を再利用し、未登録と確定した残りだけを処理する。

[結果テンプレート](assets/result.md)で `status: success | wait | error`、確認済みの登録結果、未登録の理由、未完了の key と再開条件を返す。
アダプターの `wait` と `error` は引き継ぎ、`success` は登録または既存対象との対応確認の完了だけを表す。
