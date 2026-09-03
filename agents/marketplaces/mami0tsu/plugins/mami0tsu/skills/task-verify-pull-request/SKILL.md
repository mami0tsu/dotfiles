---
name: task-verify-pull-request
description: >-
  作成されたpull requestを取得し、Draft状態と対象commitが反映されていることを確認するTask。
  Draft PRの作成結果を呼び出し元へ返す前に使う。
allowed-tools: >-
  Skill
---

# task-verify-pull-request

Draft PRを取得し、レビュー対象が整理済みの変更と一致することを確認する。
確認中はpull requestやbranchを変更しない。

## 入力

- Draft PRのURL
- 整理済みの変更

## 出力

- pull request確認結果

## 制約

- pull request、branch、commitを変更しない。
- pull requestへcommentやreviewを追加しない。
- 確認できなかった項目を成功として扱わない。
- 不一致がある場合は、Draft PRのURLを成功結果として返さない。

## 手順

### 1. Pull requestを取得する

入力されたURLからpull requestを取得する。
取得できない場合は理由を返して停止する。

### 2. Branchを確認する

base branchとhead branchが整理済みの変更と一致することを確認する。

### 3. Draft状態を確認する

pull requestがopenかつDraftであることを確認する。

### 4. Commitを確認する

整理後の対象commitがpull requestのhead branchに含まれていることを確認する。

### 5. 確認結果を返す

すべて一致した場合は、Draft状態、base branch、head branch、対象commit、URLをpull request確認結果として返す。
不一致がある場合は、その項目と実際の値を返す。
