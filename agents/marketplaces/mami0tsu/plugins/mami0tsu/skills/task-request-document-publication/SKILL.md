---
name: task-request-document-publication
description: >-
  Wikiへ書き込めるMCPがない場合に、承認済み本文の手動保存を人間へ依頼し、最終本文、正本URL、revisionを受け取るTask。
  esaまたはNotionへの公開を人間へ引き継いで再開するときに使う。
allowed-tools: >-
  Skill
---

# task-request-document-publication

承認済み本文と保存条件を人間へ渡し、保存完了まで待つ。
人間が保存した内容を最終承認された正本として扱う。

## 入力

- Document作成または更新計画
- 成果物の承認結果

## 出力

- 手動公開結果

## 制約

- provider、保存先、title、本文、公開範囲を省略しない。
- 承認済み本文を作業中に変更しない。
- URLを受け取る前に公開完了と判断しない。
- 人間が保存した本文へagentによる再承認を要求しない。

## 手順

### 1. 保存内容を提示する

provider、保存先、title、承認済み本文、公開範囲、本文digestを人間へ提示する。

### 2. 保存を依頼する

本文の保存と、正本URL、revision、保存後の最終本文、保存時の変更点の返却を依頼する。

### 3. 完了を待つ

人間から保存完了が返るまで停止する。

### 4. 結果を返す

最終本文を承認時と同じ方法で正規化してdigestを求める。
provider、正本URL、revision、最終本文、本文digest、変更点を手動公開結果として返す。
