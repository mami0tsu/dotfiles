---
name: task-verify-document
description: >-
  esaまたはNotionのDocumentを正本から再取得し、保存先、revision、本文digestが期待値と一致するか検証するTask。
  Wikiへの作成または更新後に設計正本を確定するときに使う。
allowed-tools: >-
  Skill(mami0tsu:tool-artifact-digest)
  mcp__esa__*
  mcp__notion__*
---

# task-verify-document

Documentの現在値を読み取り、期待値との差分を返す。
検証中にDocumentを変更しない。

## 入力

- 検証対象Document
- 期待するDocument状態

## 出力

- Document検証結果

## 制約

- 入力にあるproviderと正本IDを使う。
- 本文を正規化したdigestで比較する。
- URLとrevisionをproviderの正本値から取得する。
- 差分があってもDocumentを更新しない。

## 手順

### 1. Documentを取得する

正本IDでDocumentを再取得し、URL、revision、title、本文、propertyを読む。

### 2. Digestを求める

保存済み本文を`tool-artifact-digest`スキルの`digest-text`で正規化し、本文digestを求める。

### 3. 期待値と比較する

保存先、title、revision、本文digest、必要なpropertyを期待値と比較する。

### 4. 結果を返す

正本ID、URL、revision、本文digest、一致した項目、差分をDocument検証結果として返す。
