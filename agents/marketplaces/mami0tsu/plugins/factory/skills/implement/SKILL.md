---
name: implement
description: >-
  factory の着手可能な実装タスクを受け、コードや設定を変更して検証結果と Draft の成果物を記録する。
  新規実装とレビュー指摘への修正で使い、同じタスクと出力先、変更提案の対応を維持する。
compatibility: Requires CUE, Git, configured adapter skills, and repository validation tools.
allowed-tools: >-
  Read
  Write
  Edit
  Glob
  Grep
  Skill
  Bash
---

# Implement

## 入力

設定の絶対パス、実装タスクの正本 ID/URL、合意した設計、受け入れ条件を受け取る。
修正ではレビュー指摘と対象版、既存成果物の `id`、`url`、`revision`、対応する repository、base、head、worktree も受け取る。
不足は推測せず `wait` とし、設計やタスクの更新に戻す。

## 手順

1. 導入済みスキルのカタログから factory の `init` の実パスを解決し、次を直接実行する。
   標準出力の既定値補完済み JSON を使い、CUE 不在は `wait`、設定不正は `error` とする。
   設定不在ならパスを返して保留し、このスキルから初期化しない。

   ```sh
   cue export <init-dir>/assets/config.cue json: /absolute/path/factory.json --out json
   ```

2. 管理先は `roles.tasks` を使い、その binding の `adapter` を `adapters` で引く。
   `source: builtin` は factory、`external` は指定 `plugin` の `skill` をカタログから実パスへ解決する。
   SKILL.md を読み、必要な role、target.kind、operation、ツールと権限への対応を確認する。
   プラグインをまたぐ相対パスやサービス名の分岐を使わず、不在や未対応なら保留する。
   各依頼には設定パス、`role`、`target`、`operation`、`input` を渡し、書き込みにはタスクと用途から作る安定した `key` を付ける。
3. `tasks/get` でタスクと依存先を読み、`work: implement`、`states.tasks.ready`、未解消の依存がないこと、取消がないことを確認する。
   合意した設計または設計不要の根拠、受け入れ条件、対象 repository と base を正本に照合する。
4. タスクの単一 `output` を `outputs` で解決し、出力 adapter も手順2に従って確認する。
   未指定、複数値、未知のキー、受け入れ条件との矛盾なら保留する。
   記録済みの adapter、target、対象 repository、成果物の参照と照合し、同名キーの設定先が変わっても別の対象へ切り替えない。
   `repositories` は調査先であり、アイデアの管理先からも実装先を推測しない。
   実装先は選んだ `target.container` を解決して確定し、`target.kind: change` と1タスク1 repository の1変更提案を守る。
   複数 repository の変更、別の種類の出力先、範囲不足はタスクの見直しを待つ。
5. 次のケースで対象を固定する。
   導入済み `dev` の `git-usage` と `impl-flow` をカタログから解決し、worktree、base の選択、実装、検証、commit、push の必要な手順を使う。
   記録した task、repository、base、head、worktree の対応と Git の状態を確認し、dirty な変更を自動で stash、破棄、取り込みしない。

   | ケース | 作業開始前の確認 |
   | --- | --- |
   | 新規実装 | タスクの key と同じ repository、base、head に対応する既存結果を adapter で照合する。新規 ID の不在だけで `get` を要求して止めず、安定した key で未作成と再開を区別する。未作成なら確認済み base から専用 branch/worktree を用意する。既存結果があればその対応を引き継ぐ。 |
   | レビュー修正 | 同じ出力先の `staging/get` で既存成果物を読み、ID/URL、期待 revision、現在の head、指摘の対象版、worktree の対応を照合する。修正対象の指摘とタスクの範囲を確認し、同じ変更提案の head を更新する。別 PR や別 repository を作らない。 |

   既存結果の期待版が違う場合、候補が複数ある場合、取得範囲が足りない場合は保留する。
6. 対象 repository の AGENTS.md と実装規約を読み、タスクの範囲に限って変更する。
   範囲外の指摘や設計変更が必要なら、未解決事項として合意を待つ。
   必要な test、lint、build、文書を検査し、コマンド、対象 commit、結果、未検証範囲を記録する。
   変更を関心ごとに commit し、差分と検証対象版が一致することを確認する。
   push 直前にタスクの状態、依存、取消、既存 PR の期待版を再確認し、指定 head に push する。
   remote SHA が検証済み commit と一致しなければ停止し、自動で force push しない。
7. 保存直前にタスクの状態、依存、取消、output と記録済み target、既存成果物の版を再照合する。
   修正では同じ PR の ID、base、head を維持し、自分が push した検証済み新 SHA と現在の revision の一致を確かめる。
   旧記録の revision からの自分の更新を他者の更新と区別し、保存には検証済み新 revision を渡す。
   他者の更新や対応の不一致は保留する。
   同じ対象への更新を直列化し、選んだ出力先へ `staging/save` で push 済み head、明示的な base、タスク参照、key、変更と検証結果を渡す。
   未作成なら adapter 経由で Draft を1件作り、既存なら同じ PR と head を使う。
   同じ結果は再利用し、結果不明の書き込みは繰り返さず保留する。
8. 同じ出力先の `staging/get` で保存結果を再取得し、内容、task、target、ID/URL、revision と head SHA を照合する。
   タスクには既存本文と合意内容を保持し、`tasks/update` へ直前に取得したタスクの期待 revision と参照記録用の安定した key を渡す。
   同じ output、target、成果物の `id`、`url`、`revision` と Git の対応を記録する。
   `tasks/get` で記録を読み返す。
   対応を記録できなければ作成済み成果物の参照を返して保留し、再作成しない。
   [結果テンプレート](assets/result.md)で `next: review` と同じ output と target、成果物の参照と版、受け入れ条件、検証結果を呼び出し元へ返す。
   review の起動と処理枠の管理は呼び出し元に任せる。

出力は `status: success | wait | error` とし、adapter の `wait` と `error` を引き継ぐ。
`success` はレビュー可能な成果物の記録を表し、人間の承認やリリース可能状態を作らない。
このスキルでは merge、ready 化、承認を代行しない。
