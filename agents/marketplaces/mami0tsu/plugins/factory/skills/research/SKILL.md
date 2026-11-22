---
name: research
description: 登録済み Issue を調査し、判断に必要な情報を返す。
compatibility: Requires Bash, CUE (cue), and GitHub CLI (gh).
allowed-tools: >-
  Read
  Write
  Glob
  Grep
  Skill(doc:japanese-tech-writing)
  Skill(doc:cognitive-rhythm-writing)
  Skill(yomiyasu)
  Bash(bash */skills/research/scripts/check-config.sh *)
  Bash(bash */skills/research/scripts/list-research-issues.sh *)
  Bash(gh issue view *)
---

# Research

## 入力

| 項目 | 内容 |
| --- | --- |
| `factory.json` | loop から渡された設定ファイルの絶対パス |
| 登録済み Issue | loop から渡された追加調査結果とレビュー結果 |
| 調査対象 | 対象の取得、または調査する Issue の URL |
| リポジトリ | loop から渡されたリポジトリの URL と絶対パス |

## 出力

| 成果物 | 内容 |
| --- | --- |
| 調査対象 | 調査する Issue の URL 一覧 |
| 追加調査結果 | 登録済み Issue の調査結果と根拠 |

## 手順

loop からレビュー結果を受け取った場合は、[調査結果の修正](#調査結果の修正)から実行する。

### 設定の確認

1. [check-config.sh](scripts/check-config.sh) に設定ファイルの絶対パスを渡して実行し、research に必要な設定を確認する。
   設定が存在しない、不正または不足している場合は、設定パスと不足項目を loop に返して終了する。
   調査範囲の指定がなければリポジトリ全体を対象とする。

### 調査対象の取得

対象の取得を指定された場合は、この節を実行する。

1. [list-research-issues.sh](scripts/list-research-issues.sh) に設定ファイルの絶対パスを渡し、追加調査の対象を取得する。
1. Issue の一覧を loop に返して終了する。

### 登録済み Issue の追加調査

Issue の URL を指定された場合は、この節を実行する。

1. 指定された Issue の本文とコメントを `gh issue view` で確認する。
   追加調査が不要な場合は、その旨を loop に返して終了する。
1. 対象リポジトリや一次情報を調査し、既存の内容を踏まえて調査結果と根拠をまとめる。
   根拠となるリポジトリ内の箇所はパーマネントリンクで示す。
   採否や仕様を決定せず、人間の判断に必要な情報と未決事項を示す。
1. 調査結果を japanese-tech-writing、cognitive-rhythm-writing、yomiyasu の各スキルで推敲する。
1. 調査結果の末尾に、使用中のエージェント名とモデル名を入れた `Written by <Agent Name> (<Model Name>)` を記載する。
   モデル名を確認できない場合は、推測せずエージェント名だけを記載する。
1. Issue の URL、本文、追加調査結果と根拠を loop に返す。
   調査を終えたら終了する。

### 調査結果の修正

1. レビューの指摘に従って追加調査結果を修正し、loop に返して終了する。
   修正できない場合は保留する。
