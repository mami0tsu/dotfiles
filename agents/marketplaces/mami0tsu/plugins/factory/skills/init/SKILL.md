---
name: init
description: >-
  factory 設定の作成依頼または未作成時に、CUE で検証して既存設定を保護する。
compatibility: Requires Python 3 and CUE.
allowed-tools: Read AskUserQuestion Bash(python3 *)
---

## 入力

| 依存 | 値 |
| --- | --- |
| 呼び出し元 | `config` の絶対パス、新規作成時の `answers` |
| 定義 | [config.cue](assets/config.cue) |
| 実行環境 | Python 3、CUE |
| 処理 | [init_config.py](../../scripts/init_config.py) |

## 出力

`status: success | wait | error`、設定パス、作成有無、検証済み設定を返す。
[結果テンプレート](assets/result.md)で不足項目を示す。

## 制約

設定の型、制約、既定値は CUE だけで定義する。
不明な必須値は推測しない。

## 手順

1. 新規作成に必要な値を定義のコメントから確認し、回答を `answers` にまとめる。
2. `python3 <plugin-dir>/scripts/init_config.py --input <input.json>` を実行して結果を返す。
