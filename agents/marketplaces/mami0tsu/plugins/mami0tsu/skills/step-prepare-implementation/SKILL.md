---
name: step-prepare-implementation
description: >-
  IssueまたはDocumentを読み、実装に必要な情報を確認し、リポジトリと作業用worktreeを準備するStep。
  ソフトウェア変更の作業を始める前に使う。
allowed-tools: >-
  Skill(mami0tsu:task-inspect-repository)
  Skill(mami0tsu:task-prepare-worktree)
  Skill(mami0tsu:task-read-specification)
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

`task-read-specification`スキルを使い、IssueまたはDocumentの内容を取得する。

### 2. 実装条件を確認する

目的、変更範囲、受け入れ条件、確認方法が読み取れることを確認する。

### 3. リポジトリを調べる

現在の作業リポジトリを対象リポジトリとする。
`task-inspect-repository`スキルへ仕様の読み取り結果と対象リポジトリを渡し、変更する場所、既存のルール、実行するtestやlintを調べる。

### 4. 作業場所を準備する

`task-prepare-worktree`スキルを使い、作業用のbranchとworktreeを用意する。

### 5. 準備結果を返す

IssueまたはDocumentへの参照、Issueの種類とID、仕様の読み取り結果、対象リポジトリのpath、remote、GitHub repository名、base branch、起点commit、確認方法、作業用branch、worktreeを実装準備結果として返す。
