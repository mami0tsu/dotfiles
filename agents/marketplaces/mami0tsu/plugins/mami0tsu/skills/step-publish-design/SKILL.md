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
  Skill(mami0tsu:task-request-diff-review)
  Skill(mami0tsu:task-request-document-publication)
  Skill(mami0tsu:task-review-diff)
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

- 設計引き渡し結果、または`reprepare-required`結果

## 制約

- 承認対象の保存先、本文digest、予定操作が変わった場合は再承認を求める。
- 部分失敗時に作成済みObjectを削除せず、成功した操作を記録して停止する。
- 作成結果が曖昧な操作を再実行せず、人間がObjectを対応付けるまで待つ。
- 管理対象外のIssueとrelationを変更しない。
- 実装Issueを、1つのリポジトリと1つのPRに対応させる。
- Git管理Documentのpull requestをReady for reviewへ変更せず、mergeしない。
- Git管理DocumentのDraft PRでは、base branchを設計作業計画のmerge先branchと一致させる。
- 外部操作が成功するたびに、次の外部操作より先に正本識別情報と完了結果をstateへ記録する。
- Stateを更新するたびに返されたstate checkpointを、次のstate操作と完了処理へ渡す。

## 手順

### 1. 公開状態を確認する

`task-verify-state`スキルでWorkflow identity、`design_body_digest`、`approved_design_digest`、完了済み操作、pending operationを確認する。
外部Objectを再取得し、記録済みの識別情報と一致しない場合は停止する。
正本を再取得して結果が一致した完了済みoperationは、対応する後続手順で再実行しない。
Pending operationは対象の現在値を取得し、反映済みなら同じoperation IDを完了済み操作へ移してpending operationを消し、未反映を確認できた場合だけ同じoperationを再開する。
結果が曖昧なpending operationでは停止し、後続operationを実行しない。
Wiki保存が完了済みなら手順3を飛ばし、検証済みの正本値を手順6へ渡す。
Draft PR作成が完了済みなら手順4を飛ばして手順5へ進み、merge確認も完了済みなら手順5を飛ばす。
Issue更新、作成、relation設定が完了済みなら、手順8では未完了operationだけを実行する。

### 2. Issue正本を準備する

Issueを正本にする場合だけ実行する。
設計を所有する既存IssueのURLを正本URLとし、本文の更新は後続のIssue群へ含める。
同じIssueのrevisionや本文digestをそのIssue自身の本文へ書くと値が循環するため、自己参照となるrevisionとdigestは本文へ保存しない。

### 3. Wikiへ設計を保存する

Wikiを正本にする場合だけ実行する。
Documentの保存先と本文を`task-request-artifact-approval`スキルへ渡し、利用可能な操作に応じて`task-create-document`スキルまたは`task-update-document`スキルを使う。
MCPで書き込む場合は、operation IDと承認済みdigestをpending operationとしてstateへ保存してから作成・更新し、結果の正本IDとURLを保存する更新で同じoperation IDを完了済み操作へ移してpending operationを消す。
その後、`task-verify-document`スキルで正本URL、revision、本文digestを取得する。
検証状態、正本識別情報、本文digest、完了マーカーを抽出し、次の外部操作より先に`task-update-state`スキルで保存する。
利用できるMCPがない場合は、operation IDと承認済みdigestをpending operationとして保存してから`task-request-document-publication`スキルで人間の保存を待つ。
この場合は手動公開結果の最終本文、URL、revision、本文digestを正本値として採用し、利用できない`task-verify-document`スキルを呼び出さない。
手動公開結果から正本識別情報、本文digest、完了マーカーだけを抽出し、同じoperation IDを完了済み操作へ移してpending operationを消す更新としてstateへ保存する。
人間が保存した本文は保存結果を最終承認として扱う。

### 4. Git管理Documentを提案する

Git管理Documentを正本にする場合だけ実行する。
`task-prepare-worktree`スキルで設計Document用のbranchとworktreeを準備し、`task-write-design-document`スキルで承認済み本文を配置する。
`task-run-verification`スキルと`task-commit-changes`スキルを実行する。
要求の読み取り結果とcommit済みの変更を`task-review-diff`スキルへ渡し、修正指摘がないことを確認する。
続いてcommit済みの変更を`task-request-diff-review`スキルへ渡し、人間のレビュー完了と修正コメントがないことを確認する。
Agentまたは人間から修正指摘が返った場合はDocumentを公開せず、承認済み設計との不一致として設計検証へ返す。
通常検証、差分レビュー、人間レビュー、commit済みの変更を検証済みの変更として`task-organize-commits`スキルへ渡す。
Branchのpush、Draft PR作成、人間によるmergeの確認を、異なるoperation IDを持つ1つの成果物計画として`task-request-artifact-approval`スキルへ渡す。
Draft PR作成計画のbase branchが、設計作業計画で確認済みのmerge先branchと一致することを確認する。
承認後はpush、Draft PR作成、merge確認の順に進め、各操作の直前に対応する1件のoperation IDと承認済みdigestだけをpending operationとして保存する。
Draft PR成果物計画、成果物の承認結果、対応するpending operationを渡し、`task-push-branch`スキル、`task-open-draft-pr`スキル、`task-verify-pull-request`スキルを実行する。
各操作の正本識別情報と結果は、同じoperation IDを完了済み操作へ移してpending operationを消す更新として、次の外部操作より先にstateへ保存する。

### 5. Git管理Documentのmergeを待つ

Draft PRを作成した場合は、人間によるReady化とmergeを待って停止する。
Draft PRの作成結果を完了済み操作へ移した後、merge確認用のoperation IDと承認済みdigestをpending operationとしてstateへ保存してから停止する。
再開時は`task-verify-merged-document`スキルでmerge済みDocumentを取得する。
pull request上で編集された本文は人間の最終承認として扱い、merge済みrevisionとdigestを正本にする。
merge済みの正本識別情報を保存し、同じoperation IDを完了済み操作へ移してpending operationを消す更新を、次の外部操作より先に`task-update-state`スキルで実行する。

### 6. 最終本文から実装Issueを再計画する

Issueが正本の場合は、まだIssue本文を更新していないため、承認済み設計本文と承認済み実装Issue計画を使う。
WikiまたはGit管理Documentが正本の場合は、確定した正本本文、正本情報、設計作業計画、承認済み実装Issue計画、承認時の`design_body_digest`を`task-plan-implementation`スキルへ渡す。
確定した正本本文のdigestが`design_body_digest`と一致する場合は、Issue境界と設計内容を維持し、計画中の正本参照だけを最終参照へ置き換える。
Digestが異なる場合は、確定した正本本文から実装Issue計画を作り直す。
Wikiを手動保存した場合やGit管理Documentをmergeした場合は、人間が確定した本文を最終承認として扱い、設計本文に対するagent reviewや人間の再承認は求めない。
`task-plan-implementation`スキルが返した計画を、後続で使う最終実装Issue計画とする。
外部Documentを正本にする最終実装Issue計画へ、計画中の参照が残る場合は停止する。
`standalone-issue`の構成不一致が返った場合はIssue群の公開を止める。
Workflow ID、state identity、承認済み設計、必要な実装単位、既存Issue、公開済み正本の最終本文と識別情報を`reprepare-required`結果として返す。

### 7. Issue群を承認する

正本の種類、URLと最終実装Issue計画から、更新、作成、relation設定を1つのIssue群として組み立てる。
WikiまたはGit管理Documentが正本の場合は、確定した正本revisionと本文digestもIssue群へ含める。
外部Documentが正本の場合は、設計を所有するIssueへ要約と正本参照だけを置き、設計本文を複製しない。
Issueが正本の場合は、承認済み設計本文、実装に必要な項目、承認時の`design_body_digest`を使うが、更新後にしか得られないrevisionと最終本文digestは置かない。
`standalone-issue`では、既存Issueへ実装範囲、受け入れ条件、確認方法、正本参照、意味上の状態を反映する計画を作る。
`tracking-issue`では、設計Issueの更新、tracking Issueの更新、実装Issue群の作成、親子関係、依存関係、意味上の状態、provider上の状態をまとめる。
複数リポジトリを扱う場合は、tracking Issueへ全体の実装概要、リポジトリ境界、実行順序を反映する。
Issue群の最終内容と予定操作を`task-request-artifact-approval`スキルへ一度だけ渡し、一群として承認してもらう。

### 8. Issue群を反映する

各既存Issueはoperation IDと承認済みdigestをpending operationとしてstateへ保存してから、`task-update-issue`スキルで一件ずつ更新する。
各新規Issueもoperation IDと承認済みdigestをpending operationとして保存してから、`task-create-issue`スキルで一件ずつ作成する。
更新結果、または作成した正本IDとURLは、同じoperation IDを完了済み操作へ移してpending operationを消す更新として、次の外部操作より先に`task-update-state`スキルで保存する。
すべてのIDを確定した後、relationごとのoperation IDと承認済みdigestをpending operationとして保存し、`task-link-issues`スキルで親子関係と依存関係を反映する。
各relationの更新結果も、同じoperation IDを完了済み操作へ移してpending operationを消す更新として、次の外部操作より先にstateへ保存する。

### 9. 引き渡し状態を検証する

各Issueを`task-verify-issue`スキルで再取得する。
設計正本への参照、対象リポジトリ、目的、変更範囲、受け入れ条件、確認方法、依存関係、意味上の状態が一致することを確認する。
`standalone-issue`は未着手で実装可能、`tracking-issue`は進行中、設計Issueは設計完了、実装Issueは未着手で実装可能とする。
Issueが正本の場合は、Issue群の全更新後に設計を所有するIssueを再取得し、そのURL、最終revision、最終本文digestを正本値として確定する。
確定した自己参照値をIssue本文へ書き戻さない。

### 10. 設計を引き渡す

Issue構成、代表IssueのURL、設計IssueのURL、正本の種類、URL、revision、digest、実装IssueのURL、対象リポジトリ、依存関係、意味上の状態、状態検証を設計引き渡し結果として返す。
`task-complete-state`スキルで状態を完了する。
