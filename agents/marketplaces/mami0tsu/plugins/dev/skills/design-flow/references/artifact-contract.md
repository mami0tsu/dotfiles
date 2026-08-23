# 設計成果物 contract

設計成果物は、単一 PR と複数 PR のどちらでも次の field を持つ。

```yaml
canonical:
  kind: repository
  url: null
  path: docs/design/example.md
  target_ref: null
  target_field: null
  revision: null
  content_sha256: 64文字の SHA-256 hex
artifact_sha256: 64文字の SHA-256 hex
summary: 設計の対象と到達点
root_ticket:
  ref: ticket:ROOT-1
  mode: existing
  title: null
decisions:
  - decision: 採用する設計
    rationale: この設計を選ぶ根拠
acceptance_criteria:
  - criterion: 検証可能な完了条件
    verification: 実行する check または確認する外部状態
pull_requests:
  - key: pr-1
    purpose: この PR だけが担う変更
    ticket_ref: ticket:ROOT-1
    branch: null
    branch_template: feature/{ticket_id}/example
    acceptance_criteria:
      - criterion: この PR 単独の検証可能な完了条件
        verification: 実行する check または確認する外部状態
    includes_design_document: true
    parent_ref: null
    blocked_by: []
    base_ref: branch:default
unresolved: []
```

## 参照形式

既存 ticket は `ticket:<provider-id>`、作成前の ticket 案は `proposal:<pull-request-key>` で参照する。
既存 ticket の branch は完全な branch 名を`branch`に置き、`branch_template`を`null`にする。
作成前の ticket では`branch`を`null`にし、`{ticket_id}`を1つだけ含む`branch_template`を持たせる。
ticket 作成後は template の`{ticket_id}`を正本 ID に置き換え、成果物の参照対応へ記録する。

`base_ref`は`branch:<branch-name>`、`branch:default`、`pr:<pull-request-key>`のいずれかにする。
作成前の依存 PR は`pr:<pull-request-key>`で参照し、ticket と branch の具体化後に対応する branch へ解決する。
`parent_ref`と`blocked_by`は ticket 参照だけを持ち、PR key や branch 名を混ぜない。

生の要求では、`root_ticket.mode`を`proposed`、`ref`を`proposal:root`にし、作成する title を持たせる。
既存 ticket では、`mode`を`existing`、`ref`を正本 ID にし、title は`null`にする。

## 正本

`canonical.kind`は`repository`、`linear`、`wiki`のいずれかにする。
repository への保存前は`url`と`revision`を`null`にできるが、承認済みの`path`を必須にする。
`target_ref`と`target_field`は`null`にする。
commit 後は immutable commit の file URL と commit OID を記録する。

Linear では`path`を`null`にし、`target_ref`を既存の`ticket:<provider-id>`または`proposal:root`にする。
`target_field`は`description`にする。
既存 issue の URL は承認前に記録し、proposal の URL は作成後に記録する。

Wiki では`path`、`target_ref`、`target_field`を`null`にし、保存後の URL と revision を記録する。
API が immutable revision を返さない場合は、再取得した本文の SHA-256を revision の代わりに使う。

`canonical.content_sha256`は、正本へ保存する Markdown 本文の UTF-8 byte 列から計算する。
repository の blob、Linear の再取得本文、Wiki の再取得本文はこの値と照合する。

`artifact_sha256`は、`artifact_sha256`、`canonical.url`、`canonical.revision`を除く成果物を key 順の canonical JSON と末尾 LF に正規化し、UTF-8 byte 列から計算する。
保存後に正本の識別情報を追加しても、承認済み設計の digest は変えない。
`canonical.content_sha256`を計算対象へ含めるため、承認済み成果物は正本本文の digest を拘束する。
2つの digest 自体は目的が異なるため、一致を要求しない。

## 単一 PR

`pull_requests`は1件だけにする。
既存 ticket では root ticket 自体を実装 ticket として使い、余分な子 ticket を作らない。
生の要求では root ticket 案と同じ`proposal:root`を`ticket_ref`に使う。
`blocked_by`は既存の外部依存だけを持ち、`base_ref`は`branch:default`にする。

repository が正本の場合だけ`includes_design_document`を`true`にする。
Linear または Wiki が正本の場合は、すべての PR で`false`にする。

## 複数 PR

`pull_requests`は実装と review が独立して成立する境界ごとに分ける。
各項目は1つの子 ticket、1つの branch、1つの worktree、1つの PR に対応する。
作成前の子 ticket は`proposal:<pull-request-key>`で参照する。

親子関係は作業範囲の包含だけを表す。
`blocked_by`は実行順序だけを表し、親子関係から推測しない。
依存する PR の`base_ref`は直前の blocker に対応する`pr:<pull-request-key>`を指し、bottom から top の順に stack を定義する。

repository が正本の場合、`includes_design_document`を`true`にする項目は1件だけにする。
stack がある場合は最下層、独立した複数 PR の場合は設計を成立させる最初の PR に置く。
Linear または Wiki が正本の場合は、すべての項目で`false`にする。

## 承認可能性

すべての受け入れ条件は`criterion`と`verification`を持つ。
`unresolved`が空でない成果物は承認対象にしない。
PR の目的が重なる場合、または1つの受け入れ条件を複数 PR が共同でしか満たせない場合は、境界を見直す。
