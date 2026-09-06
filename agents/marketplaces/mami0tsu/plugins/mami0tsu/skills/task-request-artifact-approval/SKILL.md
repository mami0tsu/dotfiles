---
name: task-request-artifact-approval
description: >-
  外部へ書き込む成果物またはIssue群の対象、内容、予定操作、完了状態を提示し、人間の承認を受け取るTask。
  Issue群、Document、Draft PRなどの外部成果物を作成または更新する直前に使う。
allowed-tools: >-
  Skill
  Skill(mami0tsu:tool-artifact-digest)
---

# task-request-artifact-approval

利用者から見える1つの成果物または1つのIssue群について、実行する外部変更を承認対象へ固定する。
1つの成果物を成立させる複数の操作は、同じ承認へまとめる。

## 入力

- 外部成果物の変更計画

## 出力

- 成果物の承認結果

## 制約

- 対象ObjectまたはIssue一覧、本文digest、予定操作、期待する完了状態を省略しない。
- 各予定操作へ成果物内で一意なoperation IDを付ける。
- 新規Issueを含むrelationでは、作成前後で変わらない計画上のIssue keyを対象に使う。
- 同じ正規化済み操作では、再開後も同じoperation IDを使う。
- 対象、内容、予定操作のいずれかが変わった承認を再利用しない。
- 承認を受ける前に外部Objectを変更しない。
- 承認済みの範囲を広げない。

## 手順

### 1. 変更を正規化する

対象provider、container、ObjectまたはIssue一覧、作成または更新する内容、relation、状態変更を安定した順序へ正規化する。
各予定操作を、operation ID、対象、期待する現在値、反映値、期待する完了状態を持つ単位へ分ける。
新規Issueのrelationは計画上のIssue keyで正規化し、未確定の正本IDを承認対象へ混ぜない。

### 2. Digestを求める

各予定操作を共通のJSON digest操作へ渡し、operation IDごとのdigestを求める。
Operation IDとdigestの組を安定した順序に並べ、成果物全体の承認対象digestを求める。

### 3. 変更を提示する

利用者が確認できる成果物またはIssue群の単位で、対象、変更内容、予定操作、完了状態を提示する。

### 4. 承認を受け取る

明示的な承認または修正指摘を受け取る。

### 5. 結果を返す

承認の有無、承認対象digest、operation IDごとのdigest、承認範囲、修正指摘を成果物の承認結果として返す。
