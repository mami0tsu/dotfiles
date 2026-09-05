---
name: task-plan-design-work
description: >-
  要求からIssue構成、設計正本、provider、対象リポジトリ、承認単位を選び、設計作業計画を作るTask。
  設計工程の外部Objectと人間待ちを確定するときに使う。
allowed-tools: >-
  Skill
---

# task-plan-design-work

設計工程で作成または更新する成果物と、その保存先を1つの計画へまとめる。
選択肢ごとの結果を提示し、人間が選んだ値だけを確定する。

## 入力

- 要求の読み取り結果
- 既存Issue（存在する場合）

## 出力

- 設計作業計画

## 制約

- Issue構成と正本を自動選択しない。
- Issue構成と正本種別を独立して扱う。
- 1つの工程に属するIssueを複数providerまたは複数containerへ分けない。
- 複数リポジトリでも設計Issueと正本を増やさない。
- 外部Objectを変更しない。

## 手順

### 1. Issue構成を選ぶ

1つのIssueが設計と実装を担う`standalone-issue`と、親Issueの子に設計Issueと実装Issueを置く`tracking-issue`を提示する。
人間が選んだ構成を記録する。

### 2. Issueの保存先を選ぶ

利用できるproviderとcontainerを提示し、1つずつ選んでもらう。
既存Issueを使う場合は、そのproviderとcontainerを候補の基準にする。

### 3. 状態を対応付ける

意味上の状態をprovider上の状態へ対応付ける。
`standalone-issue`と実装Issueは未着手で実装可能、`tracking-issue`は進行中とする。
設計Issueは準備時の設計中と公開時の設計完了を分け、人間が選んだprovider上の状態との対応関係を記録する。

### 4. 設計正本を選ぶ

Issue、Wiki、Git管理Documentの候補と、作成、更新、手動保存、merge待ちの有無を提示する。
人間が選んだ保存先と対象Objectを記録する。

### 5. リポジトリを選ぶ

状態を保存する基準リポジトリと、設計対象となるリポジトリを確定する。
Git管理Documentでは正本を置くリポジトリとpathも確定する。

### 6. 承認単位を決める

追跡用Issue群、正本、Draft PR、実装Issue群を利用者から見える成果物単位へ分ける。

### 7. 計画を返す

Issue構成、provider、container、意味上の状態対応、正本、基準リポジトリ、対象リポジトリ、承認単位、人間待ちを設計作業計画として返す。
