---
name: pr-review-response-flow
description: 自分が author の GitHub pull request に届いた feedback を評価し、人間の判断後に修正、関心別 commit、pre-push-review、pending review への返信案作成まで進める。inline thread、review body、Conversation comment をまとめて処理するとき、stacked PR を下層から対応するとき、または中断したレビュー対応を安全に再開するときに使う。
---

# PR review response flow

PR feedback の評価から pending reply の作成までを統括する。

Agent は review を submit せず、thread を resolve せず、merge せず、即時公開 comment を作成しない。

## workflow を初期化する

対象 repository、pull request URL、認証利用者、author、base branch、head branch、head commit OID を取得する。

認証利用者が author でなければ停止する。

呼び出し元からトップレベル workflow ID を受け取った場合は、保存済み workflow identity と対象 pull request を照合する。
別の状態を初期化せず、同じ状態の`pr-review-response-flow` namespace だけを更新する。
namespace には pull request URL ごとの開始 commit OID、pending review ID、判断状態、検証済み target OID を保存する。

standalone で呼び出され、トップレベル workflow ID がない場合だけ、worktree が clean な状態で`workflow-state`を次の identity により初期化する。

```sh
python3 <workflow-state-skill-dir>/scripts/workflow_state.py init \
  --workflow-id github-pr-review-response-<owner>-<repo>-<pr-number> \
  --workflow pr-review-response-flow \
  --subject-kind pr \
  --subject <canonical-pr-url>
```

中断後は、親 workflow または standalone workflow に保存した branch と開始 commit を外部状態へ照合して再開する。

comment 本文、review 本文、返信案、credential は workflow state に保存しない。

各 PR について`gh-usage`の「pending review を識別する」を read-only で実行する。

workflow state に記録がなく、認証利用者の pending review が存在する場合は、人間が作成したものとして、repository の worktree file、Git index、commit、GitHub 上の object を変更する前に停止する。

記録済み pending review がある場合は、ID、author、state、pull request、head commit OID、canonical digest を照合する。

## stack の順序を確定する

単一 PR では、その PR だけを処理する。

stacked PR では `gh-usage` で stack を取得し、bottom から top の順に処理する。

1つの PR について pending reply まで完了してから次の PR へ進む。

下層 branch の変更を反映するために upstack を rebase した場合は、rebase 前後の merge-base と tree diff を比較する。

論理差分が変わった branch だけ feedback 評価と `pre-push-review` をやり直す。

履歴の OID だけが変わり、base と target の tree 差分が同一なら再reviewしない。

公開済み branch の履歴を書き換える必要がある場合は、自動で force push せず停止する。

## feedback を評価する

各 PR に `assess-pr-review-comments` を実行する。

全対象へ人間が `change`、`no-change`、`ask`、`ack` のいずれかを明示するまで、file、Git index、commit を変更しない。

判断待ちでは workflow state を保持して停止する。

## 修正して commit する

`change` の対象だけを修正する。

同じ `changeGroupId` の対象は1つの論理的修正として実装し、同じ commit を共有できる。

独立した `changeGroupId` は別々に通常検証し、`git-usage` で関心別に commit する。

修正と target の対応を `pr-review-response-flow` namespace に記録する。

```json
{
  "pullRequests": [
    {
      "headCommitOid": "<oid>",
      "pullRequestUrl": "<url>",
      "status": "reviewed",
      "changes": [
        {
          "changeGroupId": "change-1",
          "commitOid": "<oid>",
          "targetKeys": ["thread:<thread-id>"]
        }
      ]
    }
  ]
}
```

配列は pull request の stack 順、`changeGroupId`、`targetKey` の byte 順で安定させる。

## push 前 review を行う

全修正を commit し、worktree が clean になってから `pre-push-review` を実行する。

base と target には完全な commit OID を渡す。

actionable finding が返った場合は修正、通常検証、関心別 commit を行い、同じ sub-agent で新しい target を再検証する。

人間レビューのコメントが 0 件になるまで push と pending reply の作成へ進まない。

`pre-push-review` の完了結果に含まれる最終 target OID を workflow state へ記録する。

## 検証済み branch を push する

`git-usage` で現在の branch、remote、base、公開する commit 範囲を確認し、検証済み target を明示した branch へ push する。

push 後に GitHub の pull request head OID が検証済み target OID と一致することを確認する。

non-fast-forward rejection や意図しない remote 更新を検出した場合は、force push せず停止する。

stacked PR では bottom から top の順に push し、各 PR の head OID を確認してから次へ進む。

## pending reply を作る

`reply-to-pr-review-comments` を実行し、全判断への返信案を記録済み pending review に追加する。

`reply-to-pr-review-comments` が外部変更を検出した場合は、人間の pending comment を変更せず停止する。

全返信は submit 前の状態で残す。

利用者へ pending review URL、分類ごとの target、`CHANGED` に対応する commit OID を報告し、GitHub 上での確認と submit を委ねる。

## 完了する

各 PR について次の条件を外部状態へ照合する。

- 全 feedback に人間の判断がある。
- 全 `changeGroupId` に検証済み commit OID がある。
- `pre-push-review` が最終 target で完了している。
- GitHub の head OID が検証済み target OID と一致する。
- 全 target に pending reply object ID がある。
- pending review が `PENDING` のままで canonical digest が一致する。

stack の全 PR が条件を満たし、親 workflow ID がある場合は、`pr-review-response-flow` namespace に完了結果を記録して呼び出し元へ返す。
トップレベル状態は完了せず、呼び出し元が後続の review submit、thread resolve、merge 待ちを管理する。

standalone で初期化した workflow だけは、stack の全 PR が条件を満たした場合に`workflow-state`を complete する。

1つでも未完了、判断待ち、外部変更、認証失敗がある場合は state を保持して停止する。
