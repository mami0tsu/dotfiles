---
name: task-verify-merged-document
description: >-
  設計Documentのpull requestがmerge済みであることを確認し、merge済み本文のURL、revision、digestを取得するTask。
  Git管理Documentを設計正本として確定するときに使う。
allowed-tools: >-
  Read
  Skill(mami0tsu:tool-gh)
  Skill(mami0tsu:tool-git)
---

# task-verify-merged-document

pull requestとmerge先のDocumentを取得し、実装Issueが参照できる正本を確定する。
pull request上の人間による編集はmerge済み本文へ反映し、その内容を最終承認として扱う。

## 入力

- Draft PRのURL
- Document変更結果

## 出力

- merge済みDocument

## 制約

- pull request、branch、commit、Documentを変更しない。
- open、closed、未mergeのpull requestを成功扱いにしない。
- merge先のpathがDocument変更結果と異なる場合は停止する。
- merge済み本文を承認前の本文へ戻さない。

## 手順

### 1. Pull requestを取得する

入力URLのpull requestを取得し、repository、base、head、merge状態、merge commitを確認する。

### 2. Documentを取得する

merge commitで指定pathのDocumentを取得する。
pathまたはblobが存在しない場合は停止する。

### 3. 正本情報を作る

merge commitをrevisionとし、commitを固定したfile URLと本文digestを求める。

### 4. 結果を返す

repository、path、正本URL、revision、本文digest、merge済み本文をmerge済みDocumentとして返す。
