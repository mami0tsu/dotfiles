---
name: step-validate-design
description: >-
  設計成果物を要求整合性と必要な専門領域の独立Agentで検証し、人間の承認を得るStep。
  設計本文と実装Issue計画を外部へ公開する前に使う。
allowed-tools: >-
  Skill(mami0tsu:task-identify-review-domains)
  Skill(mami0tsu:task-request-design-approval)
  Skill(mami0tsu:task-review-design)
  Skill(mami0tsu:task-update-state)
  Skill(mami0tsu:task-verify-state)
---

# step-validate-design

設計成果物を独立した観点で検証し、公開してよい設計を1つに確定する。
必要な専門領域からAgent数を決め、固定人数を前提にしない。

## 入力

- 設計成果物

## 出力

- 承認済み設計または修正指摘

## 制約

- 要求整合性の検証をすべての設計で実行する。
- 必要な専門領域を検証できない場合は停止する。
- Agentのactionable findingを残したまま人間承認へ進まない。
- 人間の明示的な承認が得られるまで承認済み設計を返さない。
- 設計本文、Issue、Documentを変更しない。

## 手順

### 1. 公開状態を確認する

`task-verify-state`スキルで設計成果物に含まれるWorkflow ID、state identity、基準リポジトリを照合し、最新revisionを取得する。
照合できない場合は設計を検証しない。

### 2. 検証領域を決める

`task-identify-review-domains`スキルへ設計成果物を渡し、要求整合性と必要な専門領域を含む検証計画を受け取る。

### 3. 設計を検証する

`task-review-design`スキルへ設計成果物と検証計画を渡す。
修正指摘が返った場合は重複を除き、根拠、影響、修正内容、再検証方法を付けて呼び出し元へ返す。

### 4. 人間の承認を得る

Agentの修正指摘がない場合だけ、`task-request-design-approval`スキルへ設計成果物と検証結果を渡す。
訂正または疑問が返った場合は修正指摘として呼び出し元へ返す。

### 5. 承認済み設計を返す

設計成果物、検証計画、Agent検証結果、人間の承認範囲、`design_body_digest`、`approved_design_digest`を承認済み設計として返す。
`task-update-state`スキルで2つのdigest、検証状態、完了マーカーだけを記録する。
