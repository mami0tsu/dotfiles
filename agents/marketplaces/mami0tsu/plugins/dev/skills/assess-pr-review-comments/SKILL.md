---
name: assess-pr-review-comments
description: 自分が author の GitHub pull request に届いた inline thread、review body、Conversation comment を漏れなく取得し、妥当性、根拠、推奨対応、同じ修正へ収束する指摘を整理する。PR feedback を評価するとき、または修正前に人間の change、no-change、ask、ack 判断を集めるときに使う。
---

# PR review comment の評価

対象 feedback を取得して評価するが、ファイル、Git index、commit、GitHub 上の object は変更しない。

## 入力を確定する

対象 repository、pull request URL、認証利用者、head branch、head commit OID、base branch を取得する。

認証利用者が pull request の author でなければ停止する。

stack に属する場合は、bottom から top の順に並べた pull request URL と各 head commit OID を受け取る。

`workflow-state` の workflow ID と `assess-pr-review-comments` namespace を受け取る。

## feedback を取得する

`gh-usage` の「review、Conversation comment、review thread を読む」に従い、次の対象を全 page 取得する。

- 未解決と解決済みを含む inline thread
- review body
- Conversation comment

本文が同じでも object ID または URL が異なる対象を統合しない。

Agent が記録済み pending review に追加した comment と、その pending review 本体の review body は評価対象から除く。

inline feedback は thread を一つの対象とし、thread 内の全 comment を評価根拠として読む。

各対象に安定した key を付ける。

- inline thread：`thread:<thread-id>`
- review body：`review:<review-id>`
- Conversation comment：`conversation:<comment-id>`

## 指摘を評価する

各対象について、関連差分、現在の code、test、設計資料を確認し、次を示す。

- 指摘の要点
- `valid`、`invalid`、`unclear` の妥当性
- file、line、test、仕様を指す根拠
- 推奨する `change`、`no-change`、`ask`、`ack`
- 修正が必要な場合の修正範囲

同じ原因と同じ論理的修正へ収束する対象には、同じ `changeGroupId` を付ける。

本文が似ているだけの対象や、同じ file にあるだけの対象を同じ group にしない。

情報が不足する対象は `unclear` とし、推測で `change` または `no-change` に寄せない。

## 人間の判断を集める

全対象を一覧にし、人間へ target key ごとの `change`、`no-change`、`ask`、`ack` を求める。

Agent の推奨と異なる判断も、そのまま人間の判断として扱う。

一つでも判断がない対象があれば、修正を始めず状態を保持して停止する。

新しい feedback を検出した場合は対象へ追加し、その対象の判断を得るまで停止する。

## 状態を記録する

`workflow-state` で `assess-pr-review-comments` namespace に次の値を記録する。

```json
{
  "pullRequests": [
    {
      "feedbackHeadCommitOid": "<oid>",
      "pullRequestUrl": "<url>",
      "targets": [
        {
          "changeGroupId": "change-1",
          "decision": "change",
          "objectId": "<github-object-id>",
          "targetKey": "thread:<thread-id>",
          "url": "<url>"
        }
      ]
    }
  ]
}
```

`changeGroupId` は `change` の対象だけに文字列で設定し、その他では `null` にする。

`decision` は人間が判断するまで `null` にする。

`pullRequests` は stack の bottom から top の順に保持し、現在の PR entry だけを更新する。

別の PR の entry を削除または上書きしない。

`targets` は `targetKey` の byte 順で並べる。

comment 本文、review 本文、返信案、credential は保存しない。

判断を集めている間の再開では、stack 内の全 entry について pull request URL、feedback head commit OID、全 target key と object ID を GitHub の現在値へ照合する。

判断完了前に head commit または対象集合が変わった場合は再評価し、既存判断を自動で新しい対象へ移さない。

判断完了後に同じ判断から作った修正 commit へ head が進んだ場合は、既存対象の判断を維持する。

ただし、新しい feedback が加わった場合は追加対象だけを評価し、人間の判断を得るまで後続処理を停止する。

## 完了条件

現在処理している PR の全対象に人間の判断があり、`change` の全対象に `changeGroupId` があり、その PR entry の保存内容を外部状態へ照合できた場合だけ完了する。

未処理の upstack PR は、この Skill の現在の呼び出しを完了する条件に含めない。
