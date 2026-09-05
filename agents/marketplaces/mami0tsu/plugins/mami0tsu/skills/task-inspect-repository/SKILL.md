---
name: task-inspect-repository
description: >-
  要求の読み取り結果に関係するファイル、作業ルール、確認コマンドを一つのリポジトリから調べるTask。
  コード変更またはGit管理Documentの対象と確認方法を特定するときに使う。
allowed-tools: >-
  Glob
  Grep
  Read
  Skill
---

# task-inspect-repository

要求の読み取り結果と1つのリポジトリを照合し、変更作業に必要な情報を集める。
調査中はファイルやgitの状態を変更しない。

## 入力

- 要求の読み取り結果
- 対象リポジトリ

## 出力

- リポジトリ調査結果

## 制約

- ファイル、branch、worktree、commitを変更しない。
- 1回の実行で1つのリポジトリだけを調べる。
- リポジトリ内の指示を確認し、調査対象のファイルへ適用される指示に従う。
- 要求との関係を説明できないファイルを変更候補に含めない。

## 手順

### 1. リポジトリの状態を確認する

リポジトリのルート、現在のbranch、worktree、変更済みファイル、設定された全remoteを確認する。

### 2. GitHub repositoryを確認する

各remote URLをhostとcanonical `nameWithOwner`へ正規化する。
対象repositoryと一致するremoteについて、GitHub repositoryのURLとdefault branchを確認する。
対象を1つに決められない場合は停止する。

### 3. 作業ルールを確認する

リポジトリ内の指示、開発ガイド、利用できるコマンドを確認する。

### 4. 変更候補を調べる

要求に関係するコード、test、文書、設定を検索し、変更候補と影響範囲を特定する。

### 5. 確認方法を調べる

変更候補に適用するtest、lint、buildのコマンドを特定する。

### 6. 調査結果を返す

リポジトリのルート、全remoteの正規化結果、対象と一致するremote、host、canonical `nameWithOwner`、GitHub repositoryのURL、default branch、変更候補、適用する指示、確認コマンド、未解決の点をリポジトリ調査結果として返す。
