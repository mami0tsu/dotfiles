---
name: task-write-design-document
description: >-
  承認済みの設計本文を指定されたGit管理pathへ書き込み、変更結果を返すTask。
  設計DocumentのDraft PRを作るためにrepository fileを作成または更新するときに使う。
allowed-tools: >-
  Edit
  Read
  Skill(mami0tsu:tool-artifact-digest)
  Write
---

# task-write-design-document

承認済み本文を指定されたworktreeとpathへ反映する。
本文の内容を変更せず、リポジトリの文書規則と両立する場合だけ反映する。

## 入力

- 承認済み設計
- 作業場所情報
- 設計Documentのpath

## 出力

- Document変更結果

## 制約

- 入力で指定されたworktreeとpathだけを変更する。
- `design_body_digest`と一致しない設計本文を書き込まない。
- 作業開始前から存在する変更を上書きしない。
- 設計本文に新しい判断を追加しない。
- リポジトリの文書規則に合わせるため本文変更が必要な場合は、変更せず再承認が必要な差分を返す。
- commitを作らない。

## 手順

### 1. 作業場所を確認する

現在のrepository、branch、worktreeを作業場所情報と照合し、未commit変更を確認する。

### 2. 文書規則を確認する

対象pathに適用されるリポジトリの指示と既存Documentの書式を確認する。

### 3. 本文を反映する

承認済み本文を指定pathへそのまま作成または更新する。

### 4. 変更を確認する

対象pathの内容を`tool-artifact-digest`スキルの`digest-text`へ渡し、`design_body_digest`と一致することを確認する。

### 5. 結果を返す

repository、branch、worktree、path、設計を所有するIssue ID、変更前後のdigest、変更内容をDocument変更結果として返す。
