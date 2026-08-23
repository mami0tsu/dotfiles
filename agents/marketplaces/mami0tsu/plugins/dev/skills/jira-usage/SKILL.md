---
name: jira-usage
description: Atlassian Rovo MCP を使い、ticket-usage の共通 contract に従って Jira issue を取得、検索、作成、更新し、担当者、状態、親子関係、block 関係を扱うときに使う。
---

# Jira Usage

[ticket contract](../ticket-usage/references/contract.md) を読み、Atlassian Rovo MCP の Jira tool へ対応づける。
provider 固有の object を呼び出し元 flow へ渡さない。

## Jira だけへ接続する

この adapter は Jira tool だけを呼び出す。
Confluence tool、`searchAtlassian`、`fetchAtlassian`は呼び出さない。

共通 Atlassian MCP endpoint を `mcp.json`へ登録するだけでは、接続先 product を Jira に限定できない。
接続時の OAuth consent、または Atlassian Administration の Rovo MCP server permissions で Jira だけを許可する。
Jira 以外の product access が許可されている場合は接続設定の問題として報告し、この adapter からその権限を利用しない。

## Atlassian site を解決する

最初に `getAccessibleAtlassianResources`を実行し、利用可能な site と `cloudId`を取得する。
ticket URL または人間が指定した site が一件へ確定した場合だけ後続操作へ進む。
複数 site が候補になる場合は `ambiguous`として停止する。

contract の `container`は Jira project key として扱う。
`getVisibleJiraProjects`で project を取得し、key と cloudId の組み合わせを検証する。
tool schema に pagination 引数がある場合は全 page を取得し、key と cloudId の組み合わせを一件へ確定する。
site URL、cloudId、project key を workflow state に記録し、再開時に再取得結果と照合する。

## issue を読み取る

一件の取得には `getJiraIssue`を使う。
正本 ID には issue key、正本 URL には取得した site URL と key から確定した browse URL を使う。

URL 入力では、取得済み site URL と一致する host だけを受理する。
標準の `/browse/<issue-key>`または Atlassian tool が返す正本 URL から key を取得する。
custom domain を含め、取得済み site と一致しない URL から key を推測しない。

子 ticket の検索には `searchJiraIssuesUsingJql`を使う。
project と parent key を固定した JQL を組み立て、文字列を人間の自由入力から連結しない。
pagination がある場合は cursor がなくなるまで取得する。

担当者は `lookupJiraAccountId`で account ID へ解決する。
同名候補が複数ある場合は `ambiguous`として停止する。

Jira status の category key を contract の `status.type`へ次のように正規化する。

- `new`は`unstarted`
- `indeterminate`は`started`
- `done`は`completed`

未知の category key は `unsupported-field`として停止し、status 名から type を推測しない。

description が tool schema 上の文字列なら Markdown として扱う。
Atlassian Document Format などの構造化値しか取得または保存できない場合は、Markdown と可逆に変換できる実装が提供されている場合だけ変換する。
可逆性を保証できない場合は、読み書きを `unsupported-field`として停止し、field 名と provider 表現を報告する。
provider 固有 object、`null`、未取得扱いの値へ置き換えて継続しない。

## issue を作成または更新する

作成前に `getJiraProjectIssueTypesMetadata`と`getJiraIssueTypeMetaWithFields`を実行する。
project、issue type、必須 field、parent field の可用性を確認する。

作成には `createJiraIssue`、field 更新には `editJiraIssue`を使う。
実際の MCP tool schema を呼び出し直前に確認し、文書にない引数を推測しない。
作成 response の issue key は、他の書き込みへ進む前に workflow state へ保存する。

create では、要求された state を `createJiraIssue`の1回の書き込みで設定できる場合だけ作成する。
要求 state が issue type の初期状態と一致することを metadata から確定できる場合は、明示指定なしの作成を許容する。
それ以外は `unsupported-field`として書き込み前に停止し、作成後の transition で補わない。

既存 issue の状態変更には `getTransitionsForJiraIssue`で現在利用できる transition を取得し、`transitionJiraIssue`を使う。
状態名から transition ID を推測しない。

## relation を扱う

parent は create または edit の field metadata に parent field がある場合だけ設定する。
要求された issue type が parent を持てない場合は `unsupported-relation`として停止する。

block relation を読み取る前に `getIssueLinkTypes`で link type と inward、outward の意味を確認する。
`blocks`と`blockedBy`を文字列の類似だけで対応づけない。

現在の Atlassian Rovo MCP が、選択した link type を作成または削除する tool を提供しない場合は `unsupported-relation`として書き込み前に停止する。
generic link、remote link、comment、description で代用しない。
作成時に parent と block relation を同じ provider 書き込みで表現できない場合も、部分的な issue を作成せず停止する。

## 書き込み結果を検証する

書き込み後は `getJiraIssue`で issue を再取得する。
summary、description、assignee account ID、status、parent key、issue link の向きを contract の期待値と比較する。
配列順には依存しない。

Jira tool が返す version または更新時刻を条件付き更新へ使えない場合、読み取りと書き込みの間の競合は防げない。
再取得結果が期待値と異なる場合は `partial-write`として停止し、自動 rollback を試みない。

## 情報源

- [Atlassian Rovo MCP の対応 tool](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/supported-tools/)
- [Atlassian Rovo MCP の接続設定](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/getting-started-with-the-atlassian-remote-mcp-server/)
