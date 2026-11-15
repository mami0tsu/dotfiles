---
name: loop
description: >-
  factory の手動対象、周期調査、処理結果から次の子を起動し、上限と再開記録を管理する。
compatibility: Requires Python 3, CUE, native subagents, and configured adapter skills.
allowed-tools: Read Skill Agent Bash(python3 *)
---

## 入力

| 依存 | 値 |
| --- | --- |
| 呼び出し元 | 設定の絶対パス、任意の `manual` 対象、子の `results` |
| 設定 | [CUE 定義](../init/assets/config.cue)、未作成時の `init` |
| 実行環境 | Python 3、CUE、子の起動と状態確認ができる native 機能 |
| 処理先 | 設定された worker と adapter の導入済みスキル |
| 操作契約 | [runtime.md](references/runtime.md) |
| 処理 | [Python スクリプト](../../scripts/) |

## 出力

`status: success | wait | error`、子の参照、処理結果、再開位置を返す。
[結果テンプレート](assets/result.md)に従う。

## 制約

子の起動と内容判断だけを LLM が行う。
未確認の子と書き込みは処理枠を保持し、人間待ちは子の終了確認後に解放する。
review 完了後の公開判断は人間へ渡す。

## 手順

1. `loop_status.py` で既存の子を確認し、設定不在時だけ同じパスで `init` を呼ぶ。
2. 中断した子は native 状態と adapter の既存結果を照合し、`loop_reconcile.py` へ渡す。
3. `loop_discover.py` の候補ごとに `loop_claim.py` を実行し、成功時だけ native 子を起動する。
4. 子 ID を `loop_attach.py` に記録し、claim と token を子へ渡す。
5. 子は書き込み前後に `loop_write.py` を使い、結果を `loop_finish.py` に渡す。
6. 成功結果を次の `results` へ渡して繰り返し、人間待ちまたは候補なしなら結果を返す。
