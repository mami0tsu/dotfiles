---
name: step-publish-design
description: >-
  承認済み設計を選択済みの正本へ公開し、参照関係と状態を検証した実装Issueを作るStep。
  Issue、Wiki、Git管理Documentのいずれかへ設計を保存し、実装へ引き渡すときに使う。
allowed-tools: >-
  Skill(mami0tsu:task-commit-changes)
  Skill(mami0tsu:task-complete-state)
  Skill(mami0tsu:task-create-document)
  Skill(mami0tsu:task-create-issue)
  Skill(mami0tsu:task-link-issues)
  Skill(mami0tsu:task-open-draft-pr)
  Skill(mami0tsu:task-organize-commits)
  Skill(mami0tsu:task-prepare-worktree)
  Skill(mami0tsu:task-push-branch)
  Skill(mami0tsu:task-request-artifact-approval)
  Skill(mami0tsu:task-request-document-publication)
  Skill(mami0tsu:task-run-verification)
  Skill(mami0tsu:task-update-document)
  Skill(mami0tsu:task-update-issue)
  Skill(mami0tsu:task-update-state)
  Skill(mami0tsu:task-verify-document)
  Skill(mami0tsu:task-verify-issue)
  Skill(mami0tsu:task-verify-merged-document)
  Skill(mami0tsu:task-verify-pull-request)
  Skill(mami0tsu:task-verify-state)
  Skill(mami0tsu:task-write-design-document)
---

# step-publish-design

承認済み設計を正本へ保存し、その正本から実装を始められるIssueを完成させる。
外部書き込みは成果物ごとに承認とpending operationを記録してから実行する。

## 入力

- 承認済み設計

## 出力

- 設計引き渡し結果

## 制約

- 承認対象の保存先、本文digest、予定操作が変わった場合は再承認を求める。
- 部分失敗時に作成済みObjectを削除せず、成功した操作を記録して停止する。
- 作成結果が曖昧な操作を再実行せず、人間がObjectを対応付けるまで待つ。
- 管理対象外のIssueとrelationを変更しない。
- 実装Issueを、1つのリポジトリと1つのPRに対応させる。
- Git管理Documentのpull requestをReady for reviewへ変更せず、mergeしない。
- 外部操作が成功するたびに、次の外部操作より先に正本識別情報と完了結果をstateへ記録する。

## 手順

### 1. 公開状態を確認する

`task-verify-state`スキルでWorkflow identity、承認対象digest、完了済み操作、pending operationを確認する。
外部Objectを再取得し、記録済みの識別情報と一致しない場合は停止する。

### 2. Issueへ設計を保存する

Issueを正本にする場合だけ実行する。
保存先Issueと本文を`task-request-artifact-approval`スキルへ渡し、承認後に`task-update-issue`スキルで本文を更新する。
`task-verify-issue`スキルで再取得した本文が承認対象digestと一致することを確認する。

### 3. Wikiへ設計を保存する

Wikiを正本にする場合だけ実行する。
Documentの保存先と本文を`task-request-artifact-approval`スキルへ渡し、利用可能な操作に応じて`task-create-document`スキルまたは`task-update-document`スキルを使う。
利用できるMCPがない場合は`task-request-document-publication`スキルで人間の保存を待つ。
`task-verify-document`スキルで正本URL、revision、本文digestを取得する。
人間が保存した本文は保存結果を最終承認として扱い、取得したdigestを採用する。

### 4. Git管理Documentを提案する

Git管理Documentを正本にする場合だけ実行する。
`task-prepare-worktree`スキルで設計Document用のbranchとworktreeを準備し、`task-write-design-document`スキルで承認済み本文を配置する。
`task-run-verification`スキル、`task-commit-changes`スキル、`task-organize-commits`スキルを順に実行する。
BranchのpushとDraft PR作成を1つの成果物計画として`task-request-artifact-approval`スキルへ渡し、承認とpending operationの記録後に`task-push-branch`スキル、`task-open-draft-pr`スキル、`task-verify-pull-request`スキルを実行する。

### 5. Git管理Documentのmergeを待つ

Draft PRを作成した場合は、人間によるReady化とmergeを待って停止する。
再開時は`task-verify-merged-document`スキルでmerge済みDocumentを取得する。
pull request上で編集された本文は人間の最終承認として扱い、merge済みrevisionとdigestを正本にする。

### 6. 正本参照を反映する

正本の種類、URL、revision、digestを設計の所有者となるIssueへ反映する。
外部Documentが正本の場合は要約と正本参照だけを保存し、設計本文を複製しない。
この更新が以前の成果物承認に含まれない場合は、`task-request-artifact-approval`スキルで対象Issueへの変更を承認してもらい、pending operationを記録する。
`task-update-issue`スキルと`task-verify-issue`スキルで反映結果を確認する。

### 7. 実装Issueを作る

`standalone-issue`では、既存Issueへ実装範囲、受け入れ条件、確認方法、正本参照、意味上の状態を反映する。
`tracking-issue`では、実装Issue群のtitle、本文、親、依存関係、意味上の状態、provider上の状態を`task-request-artifact-approval`スキルへまとめて渡す。
複数リポジトリを扱う場合は、tracking Issueへ全体の実装概要、リポジトリ境界、実行順序を反映する。
設計Issueの状態変更、tracking Issueの更新、実装Issueの作成とrelation設定を同じIssue群の承認へ含める。
承認後に`task-create-issue`スキルで一件ずつ作り、各正本IDを次の書き込み前に`task-update-state`スキルで記録する。
すべてのIDを確定した後、`task-link-issues`スキルで親子関係と依存関係を反映する。

### 8. 引き渡し状態を検証する

各Issueを`task-verify-issue`スキルで再取得する。
設計正本への参照、対象リポジトリ、目的、変更範囲、受け入れ条件、確認方法、依存関係、意味上の状態が一致することを確認する。
`standalone-issue`は未着手で実装可能、`tracking-issue`は進行中、設計Issueは設計完了、実装Issueは未着手で実装可能とする。

### 9. 設計を引き渡す

Issue構成、代表IssueのURL、設計IssueのURL、正本の種類、URL、revision、digest、実装IssueのURL、対象リポジトリ、依存関係、意味上の状態、状態検証を設計引き渡し結果として返す。
`task-complete-state`スキルで状態を完了する。
