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
  Skill(mami0tsu:task-plan-implementation)
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

### 2. Issue正本を準備する

Issueを正本にする場合だけ実行する。
設計を所有する既存IssueのURLを正本URLとし、本文の更新は後続のIssue群へ含める。
同じIssueのrevisionや本文digestをそのIssue自身の本文へ書くと値が循環するため、自己参照となるrevisionとdigestは本文へ保存しない。

### 3. Wikiへ設計を保存する

Wikiを正本にする場合だけ実行する。
Documentの保存先と本文を`task-request-artifact-approval`スキルへ渡し、利用可能な操作に応じて`task-create-document`スキルまたは`task-update-document`スキルを使う。
MCPで書き込む場合は、pending operationをstateへ保存してから作成・更新し、結果の正本IDとURLを次の外部操作より先にstateへ保存する。
その後、`task-verify-document`スキルで正本URL、revision、本文digestを取得する。
検証状態、正本識別情報、本文digest、完了マーカーを抽出し、次の外部操作より先に`task-update-state`スキルで保存する。
利用できるMCPがない場合は、pending operationを保存してから`task-request-document-publication`スキルで人間の保存を待つ。
この場合は手動公開結果の最終本文、URL、revision、本文digestを正本値として採用し、利用できない`task-verify-document`スキルを呼び出さない。
手動公開結果から正本識別情報、本文digest、完了マーカーだけを抽出し、再開後の次の外部操作より先にstateへ保存する。
人間が保存した本文は保存結果を最終承認として扱う。

### 4. Git管理Documentを提案する

Git管理Documentを正本にする場合だけ実行する。
`task-prepare-worktree`スキルで設計Document用のbranchとworktreeを準備し、`task-write-design-document`スキルで承認済み本文を配置する。
`task-run-verification`スキル、`task-commit-changes`スキル、`task-organize-commits`スキルを順に実行する。
BranchのpushとDraft PR作成を1つの成果物計画として`task-request-artifact-approval`スキルへ渡す。
承認後は各外部操作のpending operationを保存し、`task-push-branch`スキル、`task-open-draft-pr`スキル、`task-verify-pull-request`スキルを実行する。
各操作の正本識別情報と結果は、次の外部操作より先にstateへ保存する。

### 5. Git管理Documentのmergeを待つ

Draft PRを作成した場合は、人間によるReady化とmergeを待って停止する。
再開時は`task-verify-merged-document`スキルでmerge済みDocumentを取得する。
pull request上で編集された本文は人間の最終承認として扱い、merge済みrevisionとdigestを正本にする。
merge済みの正本識別情報と完了したpending operationを、次の外部操作より先に`task-update-state`スキルで保存する。

### 6. 最終本文から実装Issueを再計画する

確定した正本本文のdigestが承認対象digestと一致する場合は、承認済みの実装Issue計画を再利用する。
Digestが異なる場合は、確定した正本本文と設計作業計画を`task-plan-implementation`スキルへ渡し、実装Issue計画を作り直す。
Wikiを手動保存した場合やGit管理Documentをmergeした場合は、人間が確定した本文を最終承認として扱い、設計本文に対するagent reviewや人間の再承認は求めない。
再計画した場合は`task-plan-implementation`スキルが返した計画を、後続で使う最終実装Issue計画とする。
`standalone-issue`の構成不一致が返った場合は公開を止め、利用者が`tracking-issue`を再選択するために必要な情報を停止理由として返す。

### 7. Issue群を承認する

正本の種類、URL、revision、digestと最終実装Issue計画から、更新、作成、relation設定を1つのIssue群として組み立てる。
外部Documentが正本の場合は、設計を所有するIssueへ要約と正本参照だけを置き、設計本文を複製しない。
Issueが正本の場合は、設計本文と実装に必要な項目を置くが、自己参照となるrevisionとdigestは置かない。
`standalone-issue`では、既存Issueへ実装範囲、受け入れ条件、確認方法、正本参照、意味上の状態を反映する計画を作る。
`tracking-issue`では、設計Issueの更新、tracking Issueの更新、実装Issue群の作成、親子関係、依存関係、意味上の状態、provider上の状態をまとめる。
複数リポジトリを扱う場合は、tracking Issueへ全体の実装概要、リポジトリ境界、実行順序を反映する。
Issue群の最終内容と予定操作を`task-request-artifact-approval`スキルへ一度だけ渡し、一群として承認してもらう。

### 8. Issue群を反映する

各既存Issueはpending operationをstateへ保存してから、`task-update-issue`スキルで一件ずつ更新する。
各新規Issueもpending operationを保存してから、`task-create-issue`スキルで一件ずつ作成する。
更新結果、または作成した正本IDとURLは、次の外部操作より先に`task-update-state`スキルで保存する。
すべてのIDを確定した後、relationごとにpending operationを保存し、`task-link-issues`スキルで親子関係と依存関係を反映する。
各relationの更新結果も、次の外部操作より先にstateへ保存する。

### 9. 引き渡し状態を検証する

各Issueを`task-verify-issue`スキルで再取得する。
設計正本への参照、対象リポジトリ、目的、変更範囲、受け入れ条件、確認方法、依存関係、意味上の状態が一致することを確認する。
`standalone-issue`は未着手で実装可能、`tracking-issue`は進行中、設計Issueは設計完了、実装Issueは未着手で実装可能とする。
Issueが正本の場合は、Issue群の全更新後に設計を所有するIssueを再取得し、そのURL、最終revision、最終本文digestを正本値として確定する。
確定した自己参照値をIssue本文へ書き戻さない。

### 10. 設計を引き渡す

Issue構成、代表IssueのURL、設計IssueのURL、正本の種類、URL、revision、digest、実装IssueのURL、対象リポジトリ、依存関係、意味上の状態、状態検証を設計引き渡し結果として返す。
`task-complete-state`スキルで状態を完了する。
