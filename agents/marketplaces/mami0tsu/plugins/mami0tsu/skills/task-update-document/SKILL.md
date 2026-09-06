---
name: task-update-document
description: >-
  esaまたはNotionの既存Documentへ承認済みの本文を反映し、正本URL、revision、digestを返すTask。
  Wiki上の設計正本を更新するときに使う。
allowed-tools: >-
  Skill(mami0tsu:tool-artifact-digest)
  mcp__esa__*
  mcp__notion__*
---

# task-update-document

既存Documentの現在値を確認し、承認済みの差分だけを反映する。
競合または想定外の変更がある場合は更新せずに停止する。

## 入力

- Document更新計画
- 成果物の承認結果
- 承認済みoperation envelope
- operation IDとdigestを含むpending operation

## 出力

- Document更新結果

## 制約

- 正本ID、更新前revision、operation ID、承認済みoperation envelopeとそのdigestを省略しない。
- Pending operationのoperation IDとdigestが承認済みoperation envelopeおよび成果物の承認結果と一致しない場合は更新しない。
- 更新計画が承認済みoperation envelopeの反映値と一致しない場合は更新しない。
- 更新前revisionが現在値と一致しない場合は変更しない。
- 承認済み本文を要約、翻訳、整形し直さない。
- 承認範囲にないpropertyや公開範囲を変更しない。
- 更新結果が曖昧な場合は同じ操作を再実行しない。

## 手順

### 1. 現在値を取得する

正本IDでDocumentを取得し、URL、revision、本文、propertyを読む。

### 2. 更新条件を照合する

承認済みoperation envelope全体を共通のJSON digest操作へ渡し、そのoperation IDとdigestが成果物の承認結果およびpending operationと一致することを確認する。
Document更新計画がoperation envelopeの反映値と同一であることを確認する。
現在のrevisionと承認済みoperation envelopeの期待する現在値が一致することを確認する。

### 3. 本文を更新する

providerに対応する利用可能な操作で、承認済み本文と承認済みpropertyだけを反映する。

### 4. 結果を返す

更新後の本文を再取得し、共通のtext digest操作へ渡して本文digestを求める。
正本ID、URL、更新後revision、本文digest、操作結果をDocument更新結果として返す。
