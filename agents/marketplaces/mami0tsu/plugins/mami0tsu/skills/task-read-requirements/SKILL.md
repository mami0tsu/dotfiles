---
name: task-read-requirements
description: >-
  自然言語の依頼、Issue読取結果、Documentから目的、範囲、制約、受け入れ条件、確認方法を読み取り、要求の読み取り結果へ整理するTask。
  設計または実装を始める前に入力の正本と不足情報を確定するときに使う。
allowed-tools: >-
  Read
  Skill
  Skill(mami0tsu:tool-artifact-digest)
  WebFetch
  mcp__esa__*
  mcp__notion__*
---

# task-read-requirements

入力元を正本として読み、設計と実装のどちらからも利用できる要求へ整理する。
記載されていない条件を推測で要件へ加えない。

## 入力

- 自然言語の依頼、Issue読取結果、またはDocument

## 出力

- 要求の読み取り結果

## 制約

- 入力元の種類、正本IDまたはURL、revisionを可能な範囲で残す。
- 事実、依頼者の判断、未確定事項、agentの推論を区別する。
- 目的、範囲、受け入れ条件、確認方法を混同しない。
- 親Issue、子Issue、関連Documentがある場合は関係を維持する。
- 取得できない入力元がある場合は、取得できた範囲と不足を明示する。

## 手順

### 1. 入力元を特定する

入力が自然言語、Issue読取結果、Documentのどれかを判定する。
Documentの場合は利用可能な参照手段で正本を取得する。

### 2. 要求を抽出する

目的、背景、対象、対象外、制約、受け入れ条件、確認方法、依存関係を原文に基づいて抽出する。

### 3. 関係を整理する

Issue読取結果にあるprovider、container、ID、親子関係と、関連Document、対象リポジトリを整理する。

### 4. 不足と矛盾を分ける

判断に必要だが記載されていない情報と、入力内で食い違う情報を別々に列挙する。

### 5. 結果を返す

`requirements_digest`を除く要求の読み取り結果を安定したJSONへ整理し、`tool-artifact-digest`スキルの`digest-json`で`requirements_digest`を求める。
入力元、正本参照、目的、範囲、制約、受け入れ条件、確認方法、依存関係、不足情報、矛盾、`requirements_digest`を要求の読み取り結果として返す。
Issueが入力元または関係先にある場合は、provider、container、Issueの種類、IDを省略しない。
