---
name: task-request-design-approval
description: >-
  Agent検証を通過した設計本文と実装Issue計画を人間へ提示し、承認または修正指摘を受け取るTask。
  設計成果物を外部へ公開する前に使う。
allowed-tools: >-
  Skill
  Skill(mami0tsu:tool-artifact-digest)
---

# task-request-design-approval

検証済みの設計成果物を人間が判断できる形で提示し、承認範囲を1つに固定する。
承認後に内容が変わった場合は、以前の承認を再利用しない。

## 入力

- 設計成果物
- Agent検証結果

## 出力

- 人間の承認結果

## 制約

- actionable findingが残っている場合は承認を求めない。
- 設計本文、実装Issue計画、Issue構成、正本、対象リポジトリを省略せず提示する。
- 曖昧な肯定を明示的な承認として扱わない。
- Issue、Document、Gitを変更しない。

## 手順

### 1. 承認対象を確認する

設計成果物に未決事項がなく、Agent検証結果に修正指摘がないことを確認する。

### 2. Digestを求める

設計本文を共通のtext digest操作へ渡し、`design_body_digest`を求める。
設計本文、実装Issue計画、Issue構成、正本、対象リポジトリを安定したJSONへ整理し、共通のJSON digest操作で承認全体を表す`approved_design_digest`を求める。

### 3. 設計を提示する

設計本文、実装Issue計画、Issue構成、正本、対象リポジトリ、検証結果を提示する。

### 4. 判断を受け取る

人間から明示的な承認、訂正、疑問のいずれかを受け取る。

### 5. 結果を返す

承認の有無、`design_body_digest`、`approved_design_digest`、承認範囲、修正指摘を人間の承認結果として返す。
