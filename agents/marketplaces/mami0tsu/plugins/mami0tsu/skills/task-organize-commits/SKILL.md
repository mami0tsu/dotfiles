---
name: task-organize-commits
description: >-
  レビュー中に生じた修正を対応する関心のcommitへまとめ、commitを整理するTask。
  検証済みの変更をpushする直前に使う。
allowed-tools: >-
  Skill
---

# task-organize-commits

人間レビューまで完了した変更のファイル内容を変えず、commitだけを整理する。
整理後のcommitをremoteへpushできる状態にする。

## 入力

- 検証済みの変更

## 出力

- 整理済みの変更

## 制約

- 修正が必要な指摘が残っている場合は停止する。
- 入力の対象commitが現在のbranchの最新commitと一致しない場合は停止する。
- commitしていない変更が残っている場合は停止する。
- remoteへ公開済みのcommitを書き換えない。
- 整理前後でファイル内容が異なる場合は完了しない。

## 手順

### 1. Commitを確認する

repository、branch、base commit、対象commit、commitしていない変更を確認する。
base commitから対象commitまでのcommitと、各修正をまとめる先を確認する。

### 2. Remote branchを確認する

作業用branchがremoteに存在しないことを確認する。
remote branchが存在する場合はcommitを整理せず停止する。

### 3. Commitをまとめる

レビュー中に生じた修正を、それぞれ同じ関心のcommitへまとめる。
既存のcommitと関心が異なる変更は、独立したcommitとして残す。

### 4. Commit messageを確認する

各commitが一つの関心だけを含むことを確認する。
各commit messageの1行目が`<type>[optional scope][!]: <description>`の形式であることを確認する[^conventional-commits]。
typeとscopeが英小文字であり、description、body、footerの説明文が日本語であることを確認する。
Issueに基づく作業では、各commit messageの1行目がIssue IDで終わることを確認する。
準拠していないcommitがある場合は整理済みの変更を返さない。

### 5. ファイル内容を確認する

整理前後の対象commitでファイル内容を比較する。
差分がある場合は整理済みの変更を返さない。

### 6. 整理済みの変更を返す

検証済みの変更、整理前後の対象commit、関心ごとの整理後commit、commit messageの確認結果、ファイル内容の比較結果を整理済みの変更として返す。

[^conventional-commits]: [Conventional Commits 1.0.0](https://www.conventionalcommits.org/ja/v1.0.0/)
