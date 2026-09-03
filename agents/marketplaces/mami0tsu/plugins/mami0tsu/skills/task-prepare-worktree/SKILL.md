---
name: task-prepare-worktree
description: >-
  仕様の読み取り結果とリポジトリ調査結果に基づき、作業用branchとworktreeを準備するTask。
  ソフトウェア変更を既存の作業から分離するときに使う。
allowed-tools: >-
  Skill
---

# task-prepare-worktree

ソフトウェア変更に使うbranchとworktreeを安全に準備する。
同じ作業に使えるworktreeがすでにある場合は、そのworktreeを再利用する。

## 入力

- 仕様の読み取り結果
- リポジトリ調査結果

## 出力

- 作業場所情報

## 制約

- 既存の変更をstash、破棄、上書きしない。
- 既存のbranchやworktreeを削除しない。
- リポジトリのbranchとworktreeの命名規則を優先する。
- 起点や作業対象を特定できない場合は、作業場所を作らず不明点を返す。
- Issueを入力とする作業でIssue IDを特定できない場合は停止する。

## 手順

### 1. 作業状態を確認する

リポジトリのルート、現在のbranch、変更済みファイル、既存のworktreeを確認する。

### 2. 既存の作業場所を確認する

同じIssueまたはDocumentのために作られたbranchとworktreeがあるか確認する。
その作業のbase branchと起点commitを確認できる場合に限り、既存のbranchとworktreeを再利用する。
再利用する場合は作業場所情報を作り、後続の手順を実行せず返す。

### 3. Branchを決める

入力で指定されたremoteにある最新のdefault branchを確認する。
確認したdefault branchがリポジトリ調査結果と一致することを確かめ、その最新commitを起点commitとする。
リポジトリの規則と変更の目的からprefixを決める。
変更内容を短い英語のkebab-caseで表したdesc-enを作る。
prefixは英小文字で書く。
Issue IDがある場合は、作業用branch名を`<prefix>/<issue-id>/<desc-en>`とする。
Issue IDがない場合は、作業用branch名を`<prefix>/<desc-en>`とする。
同名branchが別の作業に使われている場合は停止する。

### 4. Worktreeを作る

現在のworktreeを切り替えずに、新しい作業用branchとworktreeを作る。
既存のディレクトリやworktreeと重なる場合は停止する。

### 5. 作業場所情報を返す

リポジトリのルート、remote、GitHub repository名、GitHub repositoryのURL、Issueの種類とID、base branch、起点commit、作業用branch、worktreeのパスを作業場所情報として返す。
