---
name: task-inspect-repository
description: >-
  仕様の読み取り結果に関係するファイル、作業ルール、確認コマンドをリポジトリから調べるTask。
  ソフトウェア変更の対象と確認方法を特定するときに使う。
allowed-tools: >-
  Glob
  Grep
  Read
  Skill
---

# task-inspect-repository

仕様の読み取り結果とリポジトリを照合し、変更作業に必要な情報を集める。
調査中はファイルやgitの状態を変更しない。

## 入力

- 仕様の読み取り結果
- 対象リポジトリ

## 出力

- リポジトリ調査結果

## 制約

- ファイル、branch、worktree、commitを変更しない。
- リポジトリ内の指示を確認し、調査対象のファイルへ適用される指示に従う。
- 仕様との関係を説明できないファイルを変更候補に含めない。

## 手順

### 1. リポジトリの状態を確認する

リポジトリのルート、現在のbranch、worktree、変更済みファイル、remoteを確認する。

### 2. GitHub repositoryを確認する

remote URLからGitHub repository名を取得する。
remote URLに対応するGitHub repositoryのURLとdefault branchを確認する。
対象を1つに決められない場合は停止する。

### 3. 作業ルールを確認する

リポジトリ内の指示、開発ガイド、利用できるコマンドを確認する。

### 4. 変更候補を調べる

仕様に関係するコード、test、文書、設定を検索し、変更候補と影響範囲を特定する。

### 5. 確認方法を調べる

変更候補に適用するtest、lint、buildのコマンドを特定する。

### 6. 調査結果を返す

リポジトリのルート、remote、GitHub repository名、GitHub repositoryのURL、default branch、変更候補、適用する指示、確認コマンド、未解決の点をリポジトリ調査結果として返す。
