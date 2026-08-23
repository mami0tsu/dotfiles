# 設計成果物 contract

設計成果物は、単一 PR と複数 PR のどちらでも次の field を持つ。

```yaml
canonical_url: https://example.invalid/design
summary: 設計の対象と到達点
decisions:
  - decision: 採用する設計
    rationale: この設計を選ぶ根拠
acceptance_criteria:
  - 検証可能な完了条件
pull_requests:
  - key: pr-1
    purpose: この PR だけが担う変更
    acceptance_criteria:
      - この PR 単独の検証可能な完了条件
    includes_design_document: true
    parent_ticket: root
    blocked_by: []
    base: default-branch
unresolved: []
```

`canonical_url`は、保存前の承認では保存先候補を示す仮の識別子にできる。
正本へ保存した後は、repository の file URL、Linear URL、または外部 Wiki URLへ置き換える。

## 単一 PR

`pull_requests`は一件だけにする。
root ticket 自体を実装 ticket として使い、余分な子 ticket を作らない。
`blocked_by`は既存の外部依存だけを持ち、`base`は default branch にする。

## 複数 PR

`pull_requests`は実装と review が独立して成立する境界ごとに分ける。
各項目は1つの子 ticket、1つの branch、1つの worktree、1つの PR に対応する。

親子関係は作業範囲の包含だけを表す。
`blocked_by`は実行順序だけを表し、親子関係から推測しない。
依存する PR の `base`は直前の blocker に対応する branch とし、bottom から top の順に stack を定義する。

設計文書を含める項目は一件だけにする。
stack がある場合は最下層、独立した複数 PR の場合は設計を成立させる最初の PR に置く。

## 承認可能性

すべての受け入れ条件は、test、lint、build、文書検査、人間が確認できる外部状態のいずれかへ対応づける。
`unresolved`が空でない成果物は承認対象にしない。
PR の目的が重なる場合、または1つの受け入れ条件を複数 PR が共同でしか満たせない場合は、境界を見直す。
