---
name: step-prepare-implementation
description: >-
  IssueまたはDocumentを読み、実装に必要な情報を確認し、リポジトリと作業用worktreeを準備するStep。
  ソフトウェア変更の作業を始める前に使う。
allowed-tools: >-
  Skill(mami0tsu:task-inspect-repository)
  Skill(mami0tsu:task-prepare-worktree)
  Skill(mami0tsu:task-read-issue)
  Skill(mami0tsu:task-read-requirements)
  Skill(mami0tsu:task-verify-document)
  Skill(mami0tsu:task-verify-merged-document)
---

# step-prepare-implementation

IssueまたはDocumentを読み、実装を始められる状態を作る。
必要な情報が足りなければ推測で補わず、不足している内容を返す。

## 入力

- IssueまたはDocument

## 出力

- 実装準備結果

## 制約

- 実装内容や確認方法が不明な場合は停止し、不明点を返す。
- コードや文書を変更せず、commitも作らない。
- 参照するスキルが利用できない場合は、そのスキル名を含む`missing-task`を返し、操作を代行しない。

## 手順

### 1. 入力を読む

Issueが入力の場合は、先に`task-read-issue`スキルで正本を取得する。
Issueに設計正本の参照がある場合は、正本種別に対応する`task-verify-document`スキルか`task-verify-merged-document`スキルで本文、URL、revision、digestを取得し、Issueに記録された値と照合する。
正本取得手段が利用できないか、revisionかdigestが一致しない場合は停止する。
`task-read-requirements`スキルを使い、Issue読取結果と取得した設計正本を整理する。
Documentが直接入力された場合は、その内容を整理する。

### 2. 実装条件を確認する

目的、変更範囲、受け入れ条件、確認方法が読み取れることを確認する。

### 3. リポジトリを調べる

IssueかDocumentに記録された対象リポジトリを正とし、現在の作業リポジトリのremoteと照合する。
対象リポジトリを特定できないとき、remoteが一致しないときは停止し、正しいcheckoutを要求する。
`task-inspect-repository`スキルへ要求の読み取り結果と対象リポジトリを渡し、変更する場所、既存のルール、実行するtestやlintを調べる。

### 4. 作業場所を準備する

`task-prepare-worktree`スキルを使い、作業用のbranchとworktreeを用意する。

### 5. 準備結果を返す

IssueまたはDocumentへの参照、Issueの種類とID、要求の読み取り結果、対象リポジトリのpath、remote、GitHub repository名、base branch、起点commit、確認方法、作業用branch、worktreeを実装準備結果として返す。
