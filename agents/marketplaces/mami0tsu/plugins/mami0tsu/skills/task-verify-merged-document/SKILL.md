---
name: task-verify-merged-document
description: >-
  設計Documentのpull requestがmerge済みであることを確認し、merge済み本文のURL、revision、digestを取得するTask。
  Git管理Documentを設計正本として確定するときに使う。
allowed-tools: >-
  Read
  Skill(mami0tsu:tool-artifact-digest)
  Skill(mami0tsu:tool-gh)
  Skill(mami0tsu:tool-git)
---

# task-verify-merged-document

pull requestとmerge先のDocumentを取得し、実装Issueが参照できる正本を確定する。
pull request上の人間による編集はmerge済み本文へ反映し、その内容を最終承認として扱う。

## 入力

- Draft PRのURLとDocument変更結果、または正本Git Documentの参照

## 出力

- merge済みDocument

## 制約

- pull request、branch、commit、Documentを変更しない。
- open、closed、未mergeのpull requestを成功扱いにしない。
- merge先のpathがDocument変更結果と異なる場合は停止する。
- merge済み本文を承認前の本文へ戻さない。

## 手順

### 1. Pull requestを取得する

Draft PRのURLが入力された場合はpull requestを取得し、repository、base、head、merge状態、merge commitを確認する。
正本Git Documentの参照が入力された場合は、記録されたrepository、path、revisionを使い、revisionがmerge先から到達可能であることを確認する。

### 2. Documentを取得する

確認済みrevisionで指定pathのDocumentを取得する。
pathとblobの一方でも存在しない場合は停止する。

### 3. 正本情報を作る

merge commitをrevisionとし、commitを固定したfile URLを求める。
取得した本文を`tool-artifact-digest`スキルの`digest-text`へ渡し、他の正本経路と同じ本文digestを求める。

### 4. 結果を返す

repository、path、正本URL、revision、本文digest、merge済み本文をmerge済みDocumentとして返す。
