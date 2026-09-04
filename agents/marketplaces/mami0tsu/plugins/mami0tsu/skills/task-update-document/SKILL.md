---
name: task-update-document
description: >-
  esaまたはNotionの既存Documentへ承認済みの本文を反映し、正本URL、revision、digestを返すTask。
  Wiki上の設計正本を更新するときに使う。
allowed-tools: >-
  mcp__esa__*
  mcp__notion__*
---

# task-update-document

既存Documentの現在値を確認し、承認済みの差分だけを反映する。
競合または想定外の変更がある場合は更新せずに停止する。

## 入力

- Document更新計画
- 成果物の承認結果
- pending operation

## 出力

- Document更新結果

## 制約

- 正本ID、更新前revision、承認対象digestを省略しない。
- 更新前revisionが現在値と一致しない場合は変更しない。
- 承認済み本文を要約、翻訳、整形し直さない。
- 承認範囲にないpropertyや公開範囲を変更しない。
- 更新結果が曖昧な場合は同じ操作を再実行しない。

## 手順

### 1. 現在値を取得する

正本IDでDocumentを取得し、URL、revision、本文、propertyを読む。

### 2. 更新条件を照合する

現在のrevision、更新計画、承認対象digest、pending operationが一致することを確認する。

### 3. 本文を更新する

providerに対応する利用可能な操作で、承認済み本文と承認済みpropertyだけを反映する。

### 4. 結果を返す

正本ID、URL、更新後revision、本文digest、操作結果をDocument更新結果として返す。
