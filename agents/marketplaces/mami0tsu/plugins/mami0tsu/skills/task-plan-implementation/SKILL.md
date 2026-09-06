---
name: task-plan-implementation
description: >-
  設計本文を一Issue、一リポジトリ、一PRの実装単位へ分け、依存関係を含む実装Issue計画を作るTask。
  設計判断を実装可能なIssueへ変換するときに使う。
allowed-tools: >-
  Skill
---

# task-plan-implementation

設計本文の変更範囲を、独立して実装と検証ができるIssueへ割り当てる。
実装Issueには設計本文にない判断を追加しない。

## 入力

- 設計本文
- 設計作業計画
- 直前の実装Issue計画（正本確定後の再計画時）
- 確定した正本情報（公開後に存在する場合）

## 出力

- 実装Issue計画

## 制約

- 1つの実装Issueを、1つのリポジトリと、実装時に作る1つのbranch、worktree、PRに対応させる。
- 受け入れ条件を複数Issueの共同完了だけで満たす構成にしない。
- 親子関係を作業範囲、依存関係を実行順序として区別する。
- 実装用branch名と実装PRのbase branchを確定しない。
- 設計本文にない実装判断を追加しない。
- 確定した正本情報がある場合は、そのURL、revision、本文digestを省略しない。
- 確定した正本情報がある場合は、計画中の参照を実装Issue計画へ残さない。
- `standalone-issue`で複数の実装Issue、対象リポジトリ、またはPRが必要な場合は、実装Issue計画を返さず構成不一致を返す。

## 手順

### 1. 変更範囲を分ける

対象リポジトリと独立して確認できる変更単位から、実装Issueの境界を決める。

### 2. Issue本文を作る

各Issueへtitle、目的、変更範囲、受け入れ条件、確認方法、対象リポジトリのhostとcanonical repository名、設計正本の参照を設定する。
設計正本がGit管理Documentで未公開の場合は、計画中の参照としてrepository、path、merge先branchを含め、revisionと本文digestを未確定のまま残す。
Git管理Documentの確定した正本情報がある場合は、最終参照としてrepository、path、revision、本文digest、merge先branchを含める。
Wikiの確定した正本情報がある場合も、最終参照としてURL、revision、本文digestを含める。
確定した正本本文のdigestが直前の計画と一致する場合はIssue境界と本文の設計内容を維持し、計画中の参照だけを最終参照へ置き換える。
設計作業計画に役割ごとのIssue typeと必須fieldがある場合は、各実装Issueへ対応する値を設定する。
複数リポジトリを扱う`tracking-issue`には、全体の実装概要、リポジトリ境界、実行順序を置く。
リポジトリ固有の条件は対応する実装Issueだけに置く。

### 3. 関係を決める

`tracking-issue`ではすべての実装Issueを同じ親へ置く。
先行実装が必要な場合だけ`blockedBy`を設定し、親子関係から依存を推測しない。

### 4. 網羅性を確認する

設計本文の各変更範囲と受け入れ条件が、重複せず一件の実装Issueへ対応することを確認する。

### 5. 計画を返す

Issueごとのkey、Issue type、必須field、title、本文、対象リポジトリ、親、依存関係、意味上の状態、設計正本参照の確定状態と、tracking Issueの更新内容を実装Issue計画として返す。
`standalone-issue`の構成不一致では、必要な実装単位と`tracking-issue`への変更が必要であることを返す。
