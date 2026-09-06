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
  Skill(mami0tsu:task-plan-pull-request)
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
正本を再取得して結果が一致し、operation IDとoperation envelope digestの組も一致する完了済みoperationは、対応する後続手順で再実行しない。
Pending operationは対象の現在値を取得し、反映済みなら同じoperation IDとdigestの組を完了済み操作へ移してpending operationを消す。
未反映を確認できた場合だけ同じoperationを再開する。
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
Document作成または更新計画を反映値にしたoperation envelopeを作る。
Documentの保存先、本文、operation envelopeを`task-request-artifact-approval`スキルへ渡す。
作成では`task-create-document`スキル、更新では`task-update-document`スキルを使う。
MCPで書き込む場合は、operation IDと承認済みoperation envelopeのdigestをpending operationとしてstateへ保存する。
Document計画、成果物の承認結果、対応する承認済みoperation envelope、pending operationを渡して作成・更新する。
結果の正本IDとURLを保存する更新で、operation IDと承認済みoperation envelopeのdigestの組を完了済み操作へ移し、pending operationを消す。
その後、`task-verify-document`スキルで正本URL、revision、本文digestを取得する。
検証状態、正本識別情報、本文digest、完了マーカーを抽出し、次の外部操作より先に`task-update-state`スキルで保存する。
利用できるMCPがない場合は、operation IDと承認済みoperation envelopeのdigestをpending operationとして保存する。
Document計画、成果物の承認結果、対応する承認済みoperation envelope、pending operationを`task-request-document-publication`スキルへ渡して人間の保存を待つ。
この場合は手動公開結果の最終本文、正本ID、URL、revision、本文digestを正本値として採用する。
手動公開結果からprovider、container、正本ID、URL、revision、本文digest、完了マーカーだけを抽出する。
Operation IDと承認済みoperation envelopeのdigestの組を完了済み操作へ移し、pending operationを消す更新としてstateへ保存する。
人間が保存した本文は保存結果を最終承認として扱う。

### 4. Git管理Documentを提案する

Git管理Documentを正本にする場合だけ実行する。
要求の読み取り結果、正本repositoryの調査結果、設計作業計画のmerge先branch、設計Documentのpath、stateに保存済みの作業場所情報を`task-prepare-worktree`スキルへ渡し、設計Document用のbranchとworktreeを準備する。
返された作業場所情報を、次の処理より先にstateへ保存する。
`task-write-design-document`スキルで承認済み本文を配置する。
返されたDocument変更結果をstateへ保存し、再開後も同じrepository、path、branch、worktree、変更前後のdigestへ結び付ける。
`task-run-verification`スキルと`task-commit-changes`スキルを実行する。
要求の読み取り結果とcommit済みの変更を`task-review-diff`スキルへ渡し、修正指摘がないことを確認する。
続いてcommit済みの変更を`task-request-diff-review`スキルへ渡し、人間のレビュー完了と修正コメントがないことを確認する。
Agentまたは人間から修正指摘が返った場合はDocumentを公開せず、承認済み設計との不一致として設計検証へ返す。
通常検証、差分レビュー、人間レビュー、commit済みの変更を検証済みの変更として`task-organize-commits`スキルへ渡す。
整理済みの変更、正本参照、host、canonical repository、確認済みmerge先branch、作業用branch、titleか明示的な命名条件を`task-plan-pull-request`スキルへ渡し、template適用済みのDraft PR作成計画を受け取る。
Push計画、Draft PR作成計画、merge確認計画をそれぞれの反映値とし、異なるoperation IDを持つoperation envelopeを作る。
Branchのpush、Draft PR作成、人間によるmergeの確認を、operation envelopeを含む1つの成果物計画として`task-request-artifact-approval`スキルへ渡す。
Draft PR作成計画のbase branchが、設計作業計画で確認済みのmerge先branchと一致することを確認する。
承認後は、merge確認のoperation envelope全体を、入れ子構造を変えず再開artifactとしてstateへ保存する。
同じartifactへ承認対象digest、承認状態、承認範囲、operation envelope digestを保存する。
Merge確認計画はoperation envelopeの反映値へ入れ、host、canonical repository、Document path、base branch、head branch、head commitを含める。
Merge確認のoperation envelopeには本文とtitleを含めない。
承認後はpush、Draft PR作成、merge確認の順に進め、各操作の直前に対応する1件のoperation IDと承認済みoperation envelopeのdigestだけをpending operationとして保存する。
Push計画、成果物の承認結果、対応する承認済みoperation envelope、pending operationを`task-push-branch`スキルへ渡す。
Draft PR作成計画、成果物の承認結果、対応する承認済みoperation envelope、pending operationを`task-open-draft-pr`スキルへ渡す。
続いてDraft PR作成の承認済みoperation envelopeも渡し、`task-verify-pull-request`スキルを実行する。
各操作の正本識別情報と結果は、operation IDと承認済みoperation envelopeのdigestの組を完了済み操作へ移す更新として、次の外部操作より先にstateへ保存する。
Draft PR作成後の更新には、Draft PRのURL、Document変更結果、host、canonical repository、Document path、base branch、head branch、head commitを含める。
同じ更新で対応するpending operationを消す。

### 5. Git管理Documentのmergeを待つ

Draft PRを作成した場合は、merge確認用のoperation IDと承認済みoperation envelopeのdigestをpending operationとしてstateへ保存し、その後で人間によるReady化とmergeを待って停止する。
再開時はstateから検証したDraft PRのURLとDocument変更結果を取得する。
保存済みの再開artifactからmerge確認のoperation envelopeを入れ子構造のまま取得し、共通のJSON digest操作でdigestを再計算する。
再計算したdigestを保存値と照合し、反映値からmerge確認計画を取得する。
保存済みの承認対象digest、承認状態、承認範囲、operation ID、operation envelope digestからmerge確認の承認結果を再構成する。
これらとDraft PRのURL、Document変更結果、pending operationを`task-verify-merged-document`スキルへ渡し、merge済みDocumentを取得する。
pull request上で編集された本文は人間の最終承認として扱い、merge済みrevisionとdigestを正本にする。
merge済みの正本識別情報を保存し、同じoperation IDとdigestの組を完了済み操作へ移してpending operationを消す更新を、次の外部操作より先に`task-update-state`スキルで実行する。

### 6. 最終本文から実装Issueを再計画する

Issueが正本の場合は、まだIssue本文を更新していないため、承認済み設計本文と承認済み実装Issue計画を使う。
WikiまたはGit管理Documentが正本の場合は、確定した正本本文、正本情報、設計作業計画、承認済み実装Issue計画、承認時の`design_body_digest`を`task-plan-implementation`スキルへ渡す。
Issue群の反映後に再計画する場合は、作成済みIssueの検証済み対応表も渡す。
確定した正本本文のdigestが`design_body_digest`と一致する場合は、Issue境界と設計内容を維持し、計画中の正本参照だけを最終参照へ置き換える。
Digestが異なる場合は、確定した正本本文から実装Issue計画を作り直す。
Wikiを手動保存した場合やGit管理Documentをmergeした場合は、人間が確定した本文を最終承認として扱い、設計本文に対するagent reviewや人間の再承認は求めない。
`task-plan-implementation`スキルが返した計画を、後続で使う最終実装Issue計画とする。
外部Documentを正本にする最終実装Issue計画へ、計画中の参照が残る場合は停止する。
構成不一致が返った場合はIssue群の公開を止める。
公開済み正本、作成済みIssueの検証済み対応表、構成不一致の理由を含む`reprepare-required`結果を返す。
Workflow ID、state identity、承認済み設計、必要な実装単位、既存Issue、公開済み正本の最終本文と識別情報を`reprepare-required`結果として返す。

### 7. Issue群を承認する

正本の種類、URLと最終実装Issue計画から、更新、作成、relation設定を1つのIssue群として組み立てる。
WikiまたはGit管理Documentが正本の場合は、確定した正本revisionと本文digestもIssue群へ含める。
外部Documentが正本の場合は、設計を所有するIssueへ要約と正本参照だけを置き、設計本文を複製しない。
Issueが正本の場合は、承認済み設計本文、実装に必要な項目、承認時の`design_body_digest`を使うが、更新後にしか得られないrevisionと最終本文digestは置かない。
`standalone-issue`では、既存Issueへ実装範囲、受け入れ条件、確認方法、正本参照、意味上の状態を反映する計画を作る。
`tracking-issue`では、設計Issueの更新、tracking Issueの更新、実装Issue群の作成、親子関係、依存関係、意味上の状態、provider上の状態をまとめる。
複数リポジトリを扱う場合は、tracking Issueへ全体の実装概要、リポジトリ境界、実行順序を反映する。
Wikiが正本の場合は、Issue群の承認直前にも`task-verify-document`スキルで正本を確認する。
正本情報が変わっている場合はIssue群を承認しない。
新しい正本識別情報、revision、本文digestをstate checkpointによる比較更新で保存し、以前のIssue群の承認を失効させる。
更新した正本情報と最終本文を使う手順6へ戻る。
各Issue作成計画、Issue更新計画、Issue関係計画をそれぞれの反映値にしたoperation envelopeを作る。
Issue群の最終内容と、計画上のIssue keyで対象を表したoperation envelopeを`task-request-artifact-approval`スキルへ一度だけ渡し、一群として承認してもらう。

### 8. Issue群を反映する

各既存Issueはoperation IDと承認済みoperation envelopeのdigestをpending operationとしてstateへ保存する。
Issue更新計画、成果物の承認結果、対応する承認済みoperation envelope、pending operationを`task-update-issue`スキルへ渡し、一件ずつ更新する。
各新規Issueもoperation IDと承認済みoperation envelopeのdigestをpending operationとして保存する。
Issue作成計画、成果物の承認結果、対応する承認済みoperation envelope、pending operationを`task-create-issue`スキルへ渡し、一件ずつ作成する。
更新結果、または作成した計画上のIssue key、provider、container、GitHubのhostとcanonical repository、正本ID、URLをstateへ保存する。
GitHubの正本IDには正の整数Issue番号を保存し、GraphQL node IDを保存しない。
Operation IDと承認済みoperation envelopeのdigestの組を完了済み操作へ移し、pending operationを消す更新として、次の外部操作より先に`task-update-state`スキルで実行する。
すべてのIDを確定した後、検証済みの既存Issue読取結果、現在の更新結果と作成結果、stateで検証した完了済みoperationの結果から対応表を組み立てる。
対応表には計画上のIssue key、provider、container、GitHubのhostとcanonical repository、正本IDを含める。
GitHubの正本IDには正の整数Issue番号を使う。
Relationごとのoperation IDと承認済みoperation envelopeのdigestをpending operationとして保存し、Issue関係計画と対応表を`task-link-issues`スキルへ渡して親子関係と依存関係を反映する。
このとき、対応表の根拠となる検証済みIssue結果、成果物の承認結果、対応する承認済みoperation envelope、pending operationも渡す。
各relationの更新結果も、同じoperation IDとdigestの組を完了済み操作へ移してpending operationを消す更新として、次の外部操作より先にstateへ保存する。

### 9. 引き渡し状態を検証する

各Issueを`task-verify-issue`スキルで再取得する。
設計正本への参照、対象リポジトリ、目的、変更範囲、受け入れ条件、確認方法、依存関係、意味上の状態が一致することを確認する。
`standalone-issue`は未着手で実装可能、`tracking-issue`は進行中、設計Issueは設計完了、実装Issueは未着手で実装可能とする。
Issueが正本の場合は、Issue群の全更新後に設計を所有するIssueを再取得し、そのURL、最終revision、最終本文digestを正本値として確定する。
確定した自己参照値をIssue本文へ書き戻さない。
Wikiが正本の場合は、state完了の直前に`task-verify-document`スキルで再取得し、Issue群へ記録したprovider、container、正本ID、URL、revision、本文digestと一致することを確認する。
読み取り操作を利用できない場合は、人間から現在のprovider、container、正本ID、URL、revision、title、最終本文、必要なpropertyを受け取り、同じ項目を確認する。
Wikiのprovider、container、正本ID、URL、revision、本文digestのいずれかが変わっている場合は完了しない。
新しい正本識別情報、revision、本文digestを、state checkpointを用いた更新で先に保存し、以前のIssue群の承認を同じ更新で失効させる。
更新後のstate checkpointから再開する。
検証済みのIssue結果から作成済みIssueの対応表を組み立て、確定した最終本文とともに手順6へ渡す。
新しい最終実装Issue計画とIssue群を再承認し、新しいoperation IDで手順8と手順9を繰り返す。

### 10. 設計を引き渡す

Issue構成、代表IssueのURL、設計IssueのURL、正本の種類、URL、revision、digest、実装IssueのURL、対象リポジトリ、依存関係、意味上の状態、状態検証を設計引き渡し結果として返す。
`task-complete-state`スキルで状態を完了する。
