---
name: step-prepare-design
description: >-
  要求を読み、Issue構成、設計正本、対象リポジトリ、承認単位を決め、追跡用Issueと再開状態を準備するStep。
  ソフトウェア変更の設計を始める前、または保存済みの設計工程を再開するときに使う。
allowed-tools: >-
  Skill(mami0tsu:task-create-issue)
  Skill(mami0tsu:task-initialize-state)
  Skill(mami0tsu:task-inspect-repository)
  Skill(mami0tsu:task-link-issues)
  Skill(mami0tsu:task-plan-design-work)
  Skill(mami0tsu:task-read-issue)
  Skill(mami0tsu:task-read-requirements)
  Skill(mami0tsu:task-request-artifact-approval)
  Skill(mami0tsu:task-update-state)
  Skill(mami0tsu:task-verify-issue)
  Skill(mami0tsu:task-verify-state)
---

# step-prepare-design

設計に必要な入力と外部Objectを確定し、中断後も同じ作業を再開できる状態を作る。
利用者がIssue構成と正本を選ぶまで、外部Objectを変更しない。

## 入力

- 生の要求、Issue、またはDocument
- Workflow ID（再開時）
- `reprepare-required`結果（Issue構成の再選択時）

## 出力

- 設計準備結果

## 制約

- `standalone-issue`と`tracking-issue`を自動選択しない。
- Issue、Wiki、Git管理Documentのいずれを正本にするか人間に選んでもらう。
- 1つの工程に属するIssueは、同じproviderとcontainerへ置く。
- 複数リポジトリでも設計Issueと正本は1つにする。
- 外部書き込み前に、対象成果物の承認とpending operationの記録を完了する。
- 作成結果が曖昧な操作を再実行しない。
- Stateを更新するたびに返されたstate checkpointを、次のstate操作へ渡す。
- Issue構成の再選択では、公開済み正本と完了済み外部操作を変更しない。

## 手順

### 1. 要求を読む

既存Issueが入力に含まれる場合は、先に`task-read-issue`スキルで現在状態と正本URLを取得する。
`task-read-requirements`スキルへ生の要求、Issue読取結果、またはDocumentを渡し、要求の読み取り結果を受け取る。

### 2. 設計作業を計画する

`task-plan-design-work`スキルへ要求の読み取り結果、既存Issue、利用可能な`reprepare-required`結果を渡す。
Issue構成、provider、container、正本、基準リポジトリ、対象リポジトリ、承認予定を含む設計作業計画を受け取る。

### 3. 状態を準備する

Workflow IDがない場合は、入力元の種類ごとに不変なsubjectを選び、`task-initialize-state`スキルへ渡す。
生の要求では`requirement`と`requirements_digest`、Issueでは`issue`とprovider、container、正本IDを組み合わせた識別子、Documentでは`document`とprovider、正本IDを組み合わせた識別子を使う。
初期化結果が生成したWorkflow IDを、以後の設計工程で使う。
新規stateでは、設計作業計画のdigestを外部書き込み前に`task-update-state`スキルで保存する。
通常の再開では、同じ入力元の不変なsubjectを使って`task-verify-state`スキルを実行し、保存済みidentityと設計作業計画のdigestを照合する。
`reprepare-required`結果から再開する場合は、結果に含まれるstate identityと変更前の設計作業計画を使って先に`task-verify-state`スキルを実行する。
未完了または曖昧なpending operationがないことと、新しい計画との差分がIssue構成、既存Issueの役割、対応する実装計画だけであることを確認する。
確認後は新しい計画digestを保存し、Issue構成と実装計画に対する以前の承認を失効させる更新を`task-update-state`スキルで行う。
更新後のstate checkpointを使って新しい設計作業計画を再検証し、その後にだけ外部書き込みへ進む。
Issue本文、Document本文、relation、revisionの変更からsubjectを再計算しない。

### 4. 追跡用Issueを準備する

`standalone-issue`では既存Issueがなければ1件を作成対象にする。
`tracking-issue`では、親となるtracking Issueと子となる設計Issueの役割を既存Issueへ割り当て、足りないIssueを作成対象にする。
既存のtracking Issueを親にする場合も、設計Issueを省略しない。
`standalone-issue`から再選択する場合は、設計作業計画で選ばれた既存Issueの役割に従い、もう一方だけを作成対象にする。
各Issue作成計画とIssue関係計画を反映値にしたoperation envelopeを作る。
作成対象のIssue群、計画上のIssue keyで表した親子関係、operation envelopeを`task-request-artifact-approval`スキルへ渡し、1回だけ承認してもらう。
作成対象がある場合は、各Issueのoperation IDと承認済みoperation envelopeのdigestをpending operationとしてstateへ記録する。
Issue作成計画、成果物の承認結果、対応する承認済みoperation envelope、pending operationを`task-create-issue`スキルへ渡し、1件ずつ作成する。
作成応答を受けたら、計画上のIssue key、provider、container、GitHubのhostとcanonical repository、正本ID、URLを保存する。
Operation IDと承認済みoperation envelopeのdigestの組を完了済み操作へ移し、pending operationを消す更新を、次の外部操作より先に`task-update-state`スキルで実行する。
すべてのIDが確定したら、検証済みの既存Issue読取結果、現在の作成結果、stateで検証した完了済みoperationの結果から対応表を組み立てる。
対応表には計画上のIssue key、provider、container、GitHubのhostとcanonical repository、正本IDを含める。
親子関係のoperation IDと承認済みoperation envelopeのdigestをpending operationとして保存し、Issue関係計画と対応表を`task-link-issues`スキルへ渡して設計Issueを`tracking-issue`の子にする。
このとき、対応表の根拠となる検証済みIssue結果、成果物の承認結果、対応する承認済みoperation envelope、pending operationも渡す。
関係の更新結果も、operation IDと承認済みoperation envelopeのdigestの組を完了済み操作へ移す更新として、次の外部操作より先にstateへ保存する。
同じ更新で対応するpending operationを消す。
再開時は、正本を再取得し、operation IDとoperation envelope digestの組が一致する完了済みoperationを飛ばす。
Pending operationは対象の現在値を取得し、反映済みなら同じoperation IDとdigestの組を完了済み操作へ移してpending operationを消す。
未反映を確認できた場合だけ同じoperationを再開する。
結果が曖昧なpending operationでは停止し、後続operationを実行しない。

### 5. リポジトリを調べる

対象リポジトリごとに`task-inspect-repository`スキルを実行する。
各結果を対象リポジトリに対応付け、別のリポジトリの事実を混ぜない。

### 6. 準備結果を返す

要求の読み取り結果、設計作業計画、Workflow ID、state identity、追跡用Issue、対象リポジトリごとの調査結果を設計準備結果として返す。
まだ保存していない外部Objectの識別情報、調査結果のdigest、完了マーカーだけを`task-update-state`スキルで記録する。
