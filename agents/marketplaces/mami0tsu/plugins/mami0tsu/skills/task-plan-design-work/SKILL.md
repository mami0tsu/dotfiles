---
name: task-plan-design-work
description: >-
  要求からIssue構成、設計正本、provider、対象リポジトリ、承認単位を選び、設計作業計画を作るTask。
  設計工程の外部Objectと人間待ちを確定するときに使う。
allowed-tools: >-
  Skill
  Skill(mami0tsu:tool-artifact-digest)
  mcp__atlassian__*
  mcp__linear__*
---

# task-plan-design-work

設計工程で作成または更新する成果物と、その保存先を1つの計画へまとめる。
選択肢ごとの結果を提示し、人間が選んだ値だけを確定する。

## 入力

- 要求の読み取り結果
- 既存Issue（存在する場合）
- `reprepare-required`結果（Issue構成または実装境界の再選択時）

## 出力

- 設計作業計画

## 制約

- Issue構成と正本を自動選択しない。
- Issue構成と正本種別を独立して扱う。
- 1つの工程に属するIssueを複数providerまたは複数containerへ分けない。
- 複数リポジトリでも設計Issueと正本を増やさない。
- 再選択では、provider、container、基準リポジトリ、対象リポジトリ、公開済み正本、作成済みIssueの対応表、完了済み外部操作を変更しない。
- Git管理Documentのmerge先branchを推測で確定しない。
- 外部Objectを変更しない。

## 手順

### 1. Issue構成を選ぶ

1つのIssueが設計と実装を担う`standalone-issue`と、親Issueの子に設計Issueと実装Issueを置く`tracking-issue`を提示する。
人間が選んだ構成を記録する。
`reprepare-required`結果がある場合は`tracking-issue`を選択対象とし、既存の`standalone-issue`をtracking Issueと設計Issueのどちらへ再利用するか選んでもらう。
作成済みIssueの実装境界に構成不一致がある場合は、各計画上のIssue keyと正本IDの対応を維持できる修正方針を選んでもらう。
既存keyの削除または別の実装単位への再利用が必要な方針では、計画を確定しない。

### 2. Issueの保存先を選ぶ

利用できるproviderとcontainerを提示し、1つずつ選んでもらう。
既存Issueを使う場合は、そのproviderとcontainerを候補の基準にする。
GitHubではhostとcanonical repository名を分離せず、両方をIssue保存先として計画へ記録する。
Jiraを選ぶ場合はproject metadataを取得し、tracking、設計、実装、standaloneの各役割で利用できるIssue typeと必須fieldを提示する。
利用者が選んだIssue typeと、必須fieldへ設定する値を役割ごとに記録する。
必要なmetadataを取得できない場合や必須fieldの値が未確定の場合は、Issue作成を含む計画を確定しない。
Linearを選ぶ場合はteamとworkflow stateのmetadataを取得し、containerと意味上の状態へ対応するIDを記録する。

### 3. 状態を対応付ける

意味上の状態をprovider上の状態へ対応付ける。
`standalone-issue`は準備時の設計中と公開時の未着手で実装可能を分ける。
`tracking-issue`は進行中、設計Issueは準備時の設計中と公開時の設計完了、実装Issueは未着手で実装可能とする。
各意味上の状態と、人間が選んだprovider上の状態との対応関係を記録する。

### 4. 設計正本を選ぶ

Issue、Wiki、Git管理Documentの候補と、作成、更新、手動保存、merge待ちの有無を提示する。
人間が選んだ保存先と対象Objectを記録する。
`reprepare-required`結果がある場合は、公開済み正本とその最終本文を変更せず計画へ引き継ぐ。

### 5. リポジトリを選ぶ

状態を保存する基準リポジトリと、設計対象となるリポジトリを確定する。
各リポジトリはhostとcanonical repository名で識別し、GitHubでは`nameWithOwner`を使う。
Git管理Documentでは正本を置くhost、canonical repository、pathも確定する。
正本リポジトリのmetadataから既定branchを候補として取得し、Git管理Documentのmerge先branchを人間に確認して計画へ記録する。

### 6. 承認単位を決める

追跡用Issue群、正本、Draft PR、実装Issue群を利用者から見える成果物単位へ分ける。

### 7. 計画を返す

Issue構成、既存Issueの役割、作成済みIssueの対応表、provider、container、GitHubのhostとcanonical repository、役割ごとのIssue typeと必須field、意味上の状態対応、正本、Git管理Documentのmerge先branch、基準リポジトリ、対象リポジトリ、承認単位、人間待ちを設計作業計画としてまとめる。
計画を共通のJSON digest操作へ渡し、計画digestと設計作業計画を返す。
