---
name: task-request-document-publication
description: >-
  Wikiへ書き込めるMCPがない場合に、承認済み本文の手動保存を人間へ依頼し、最終本文、正本ID、URL、revisionを受け取るTask。
  esaまたはNotionへの公開を人間へ引き継いで再開するときに使う。
allowed-tools: >-
  Skill
  Skill(mami0tsu:tool-artifact-digest)
---

# task-request-document-publication

承認済み本文と保存条件を人間へ渡し、保存完了まで待つ。
人間が保存した内容を最終承認された正本として扱う。

## 入力

- Document作成または更新計画
- 成果物の承認結果
- 承認済みoperation envelope
- operation IDとdigestを含むpending operation

## 出力

- 手動公開結果

## 制約

- provider、保存先、title、本文、公開範囲を省略しない。
- 承認済みoperation envelopeのoperation IDとdigestが成果物の承認結果に含まれない場合は依頼しない。
- Pending operationのoperation IDとdigestが承認済みoperation envelopeおよび成果物の承認結果と一致しない場合は依頼しない。
- 公開計画が承認済みoperation envelopeの反映値と一致しない場合は依頼しない。
- 承認済み本文を作業中に変更しない。
- 正本IDとURLを受け取る前に公開完了と判断しない。
- 人間が保存した本文へagentによる再承認を要求しない。

## 手順

### 1. 保存内容を提示する

承認済みoperation envelope全体を共通のJSON digest操作へ渡し、そのoperation IDとdigestが成果物の承認結果およびpending operationと一致することを確認する。
Document作成または更新計画がoperation envelopeの反映値と同一であることを確認する。
provider、保存先、title、承認済み本文、公開範囲、本文digestを人間へ提示する。

### 2. 保存を依頼する

本文の保存と、provider、container、正本ID、URL、revision、保存後の最終本文、保存時の変更点の返却を依頼する。

### 3. 完了を待つ

人間から保存完了が返るまで停止する。

### 4. 結果を返す

最終本文を共通のtext digest操作で正規化してdigestを求める。
provider、container、正本ID、URL、revision、最終本文、本文digest、変更点を手動公開結果として返す。
