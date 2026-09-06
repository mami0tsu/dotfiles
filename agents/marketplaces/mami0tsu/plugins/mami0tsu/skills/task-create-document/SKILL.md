---
name: task-create-document
description: >-
  承認済みの本文をesaまたはNotionへ一件のDocumentとして作成し、正本URL、revision、digestを返すTask。
  Wikiを設計の正本として新規作成するときに使う。
allowed-tools: >-
  Skill(mami0tsu:tool-artifact-digest)
  mcp__esa__*
  mcp__notion__*
---

# task-create-document

承認済みの本文からDocumentを一件だけ作る。
作成結果が曖昧な場合は再作成せず、人間による対応付けを待つ。

## 入力

- Document作成計画
- 成果物の承認結果
- operation IDとdigestを含むpending operation

## 出力

- Document作成結果

## 制約

- provider、container、親Document、title、本文を推測で補わない。
- 作成計画のoperation IDとdigestが成果物の承認結果に含まれない場合は作成しない。
- Pending operationのoperation IDとdigestが作成計画および成果物の承認結果と一致しない場合は作成しない。
- 承認済み本文を要約、翻訳、整形し直さない。
- 1回の実行で1件だけ作る。
- 正本IDを確認できない場合は同じ作成操作を再実行しない。

## 手順

### 1. 作成内容を照合する

作成計画を共通のJSON digest操作へ渡し、計画、成果物の承認結果、pending operationのoperation IDとdigestが三者で一致することを確認する。
保存先、title、本文、公開範囲を作成計画と照合する。

### 2. Documentを作る

providerに対応する利用可能な操作で、承認済み本文をそのまま保存する。

### 3. 正本を取得する

作成応答から正本IDとURLを取得し、そのIDでDocumentを再取得する。
正本IDが曖昧な場合は、同じcontainerからtitleと作成時刻が近い候補を列挙する。

### 4. 結果を返す

再取得した本文を共通のtext digest操作へ渡して本文digestを求める。
provider、正本ID、URL、revision、本文digest、操作結果をDocument作成結果として返す。
結果が曖昧な場合は、候補と人間による対応付けが必要であることを返す。
