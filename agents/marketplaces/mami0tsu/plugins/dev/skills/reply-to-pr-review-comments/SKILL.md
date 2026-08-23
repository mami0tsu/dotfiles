---
name: reply-to-pr-review-comments
description: 人間が判断済みの GitHub PR feedback への返信案を CHANGED、NO-CHANGE、ASK、ACK に分類し、記録済みの Agent 所有 pending review だけへ追加する。inline reply、review body、Conversation comment への URL 付き回答を submit せず準備するとき、または中断後に同じ pending review へ安全に再開するときに使う。
---

# PR review comment への pending reply

承認済みの判断と実装結果から返信案を作り、`gh-usage` を使って記録済み pending review だけを更新する。

review の submit、thread の resolve、merge、即時公開 comment は実行しない。

## 入力を検証する

pull request URL、GitHub 上の現在の head commit OID、検証済み target commit OID、`workflow-state` の workflow ID、`assess-pr-review-comments` namespace を受け取る。

全 target に人間の判断が記録されていなければ停止する。

`change` には検証済み commit OID と対応する `changeGroupId` を必須とする。

`no-change`、`ask`、`ack` では commit OID を要求しない。

GitHub 上の head commit と検証済み target commit が異なる場合は、上位 flow へ push 状態の確認を要求する。

全 feedback を再取得し、評価済み target key と object ID が現在も存在することを確認する。

新しい feedback がある場合は、上位 flow へ追加対象の評価と人間判断を要求する。

## 返信案を作る

判断を次の接頭辞へ対応づける。

- `change`：`CHANGED:`
- `no-change`：`NO-CHANGE:`
- `ask`：`ASK:`
- `ack`：`ACK:`

`CHANGED` には変更内容と検証済み commit OID を書く。

同じ `changeGroupId` の複数 target には同じ commit OID を使ってよいが、target ごとの返信は個別に作る。

`NO-CHANGE` には変更しない根拠を、`ASK` には確認したい一点を、`ACK` には受領した事実を短く書く。

## pending review を保護する

`gh-usage` の「pending review を識別する」に従い、Agent が作成して workflow state に記録した pending review ID と canonical digest を照合する。

記録にない認証利用者の pending review が存在する場合は、人間が作成したものとして停止する。

記録済み pending review がない場合だけ、`gh-usage` で event を指定せず新規作成し、ID と digest を追加操作より前に保存する。

各 mutation の直前と成功後に digest を照合する。

期待値と異なる場合は、人間が追加または編集した pending comment を変更せず停止する。

## 返信を配置する

inline thread には、記録済み pending review ID を指定して thread reply を追加する。

review body への回答は pending review body に追加する。

Conversation comment への回答は、元 comment の URL と返信案を pending review body に追加する。

既存 pending review body は全文を再取得し、Agent が記録した digest と一致する場合だけ更新する。

同じ target key に記録済み reply object ID がある場合は重複して追加せず、GitHub 上に同じ object が存在することを確認する。

## 状態を記録する

`workflow-state` で `reply-to-pr-review-comments` namespace に次の値を記録する。

```json
{
  "pullRequests": [
    {
      "pendingReviewDigest": "<sha256>",
      "pendingReviewId": "<review-id>",
      "pullRequestUrl": "<url>",
      "replies": [
        {
          "category": "CHANGED",
          "commitOid": "<oid>",
          "replyObjectId": "<github-object-id>",
          "targetKey": "thread:<thread-id>"
        }
      ],
      "validatedHeadCommitOid": "<oid>"
    }
  ]
}
```

`commitOid` は `CHANGED` だけに設定し、その他では `null` にする。

`pullRequests` は stack の bottom から top の順に保持し、現在の PR entry だけを更新する。

別の PR の entry を削除または上書きしない。

`replies` は `targetKey` の byte 順で並べる。

comment 本文、review 本文、返信案、credential は保存しない。

mutation が成功したら、その object ID と更新後 digest を次の mutation より前に保存する。

応答を取得できない中断では操作を再試行せず、GitHub の現在状態を再取得してから再開する。

## 完了条件

現在処理している PR の全 target key に対応する reply object ID があり、その pending review が `PENDING` のままで、保存済み digest と GitHub の現在値が一致した場合だけ完了する。

未処理の upstack PR は、この Skill の現在の呼び出しを完了する条件に含めない。
