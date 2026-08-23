---
name: dev-flow
description: root ticket 配下の設計、ticket 反映、実装、review response、merge 待ちを調整し、現在状態から下位 flow を選んで全実装 PR の merge まで再開可能に進める開発工程 coordinator。生の要求、既存 root ticket、単一 PR、stacked PR を開発するときに使う。
---

# Development Flow

生の要求または人間が指定した root ticket を、1つの開発工程として調整する。
設計、ticket graph、実装、review response は対応する下位 flow に委譲し、この flow へ内部状態を複製しない。

Agent は review を submit せず、review thread を resolve せず、pull request を merge しない。
これらは人間の操作を待ち、再実行時に外部状態を検証してから続きを選ぶ。

## 作業範囲を確定する

root ticket が指定された場合は、`ticket-usage`で本文、状態、親、直下の子 ticket、block 関係、正本 URL を取得する。
指定された ticket をこの workflow の root とし、その ticket と、親をたどって root に到達する子孫だけを実装対象にする。
provider 上でさらに親を持っていても、指定された root より上へ作業範囲を広げない。

root 配下の ticket が範囲外 ticket に block されている場合、その relation は削除せず、範囲外 ticket も実装しない。
blocker の状態と対応する pull request を待機条件として記録し、解消後の再取得まで対象 ticket を進めない。
範囲外 ticket が root 配下を block していても、その ticket の子や blocker を探索して作業範囲へ加えない。

ticket がない生の要求では、`design-flow`に root ticket 案を含む設計を作らせる。
人間が root ticket 案と設計成果物を承認するまで provider へ書き込まない。
承認後は`ticket-flow`に root ticket の作成と実装 ticket graph の反映を委譲し、返された正本 root ticket URL を以後の workflow identity にする。

## workflow state を管理する

root ticket の正本 URL が確定したら、`workflow-state`を使い、provider と root ticket ID を含む workflow ID、workflow `dev-flow`、subject kind `ticket`でトップレベル状態を初期化する。
生の要求から開始した場合は、`design-flow`と`ticket-flow`が root ticket の正本 ID を確定するまで、その承認済み成果物と各下位 flow の再開情報を引き継ぐ。
正本 URL が確定した直後にトップレベル状態を初期化し、下位 flow の完了記録を同じ状態の namespace へ関連付ける。

`dev-flow` namespace には次の調整情報だけを保存する。

- root ticket の provider、ID、正本 URL
- root 配下として検証した ticket ID の集合
- ticket ごとの選択済み工程と完了、待機、失敗の状態
- 実装 ticket、branch、pull request URL、stack ID の対応
- 範囲外 blocker の ticket ID と待機理由
- review submit、thread resolve、merge の人間待ち
- 外部状態を最後に検証した revision、commit OID、または provider の更新時刻

設計成果物、ticket 本文、review 本文、返信案、credential は保存しない。
`design-flow`、`ticket-flow`、`impl-flow`、`pr-review-response-flow`の namespace を読み、その内部 field を`dev-flow` namespace へ複製しない。

再実行時は保存値だけで工程を決めない。
root ticket と子孫、block 関係、pull request の base、head、Draft、merge、review、stack の状態を provider と GitHub から再取得する。
保存済み identity と外部状態が一致しない場合は、状態を上書きせず差分を報告して停止する。

## 現在状態から工程を選ぶ

各工程の前提を上から評価し、まだ完了していない最初の工程を選ぶ。
同じ ticket または pull request に複数の工程を同時に実行しない。

1. 承認済み設計または実装可能な受け入れ条件がなければ、`design-flow`を実行する。
2. 承認済み設計が ticket graph へ未反映なら、`ticket-flow`を実行する。
3. 実装 ticket に pull request がなく、範囲内 blocker の実装順と範囲外 blocker の待機条件を満たすなら、`impl-flow`を一件実行する。
4. pull request に未処理 feedback があれば、`pr-review-response-flow`を実行する。
5. pending review があれば review submit を、未解決 thread があれば thread resolve を人間待ちとして記録する。
6. review 条件、必須 check、blocker pull request の merge を満たした実装 pull request は、人間による merge 待ちとして記録する。
7. 全実装 pull request が merge 済みなら完了する。

設計成果物が存在しても、正本、承認範囲、成果物 digest を照合できなければ`design-flow`へ戻す。
ticket が存在しても、受け入れ条件、branch、base、block 関係が具体化されていなければ`impl-flow`へ渡さない。

## 設計と ticket 反映を委譲する

`design-flow`には生の要求または root ticket、トップレベル workflow ID があればその ID を渡す。
返された承認済み成果物について、正本 URL、成果物と正本本文の SHA-256、PR 分割、親子関係、block 関係、stack 順序を確認する。

`ticket-flow`には同じ workflow ID と承認済み成果物を渡す。
返された root ticket と実装 ticket を relation 付きで再取得し、すべてが root の子孫であることを確認する。
単一 PR では root ticket 自体を実装対象とし、複数 PR では成果物に対応する直下または子孫の実装 ticket だけを対象にする。

成果物外の既存 sub-issue は自動で削除、更新、実装しない。
今回の承認済み設計へ含める必要がある場合は、`design-flow`へ戻して人間の承認を取り直す。

## 実装を委譲する

実装可能な ticket を、block 関係と stack の bottom から top の順で一件ずつ`impl-flow`へ渡す。
下位 flow へはトップレベル workflow ID、root ticket ID、対象 ticket ID、承認済み設計成果物の参照を渡す。

`impl-flow`が返した ticket、branch、base、pull request URL、stack ID を外部状態へ照合する。
pull request が Draft であり、ticket が root 配下にあり、base が ticket の blocker と一致する場合だけ、その実装工程を完了として記録する。

範囲内に並行実行できる ticket が複数あっても、同じ worktree、branch、pull request、stack を共有させない。
範囲外 blocker、未確定 base、複数 stack に分かれた blocker がある ticket は待機させ、近い branch を推測しない。

## review response を委譲する

root 配下の実装 pull request と stack を`gh-usage`で再取得する。
未処理 feedback がある pull request だけを`pr-review-response-flow`へ渡す。

stacked pull request は bottom から top の順で処理する。
下層 pull request の response、検証、push、pending reply が完了するまで上層へ進まない。
下層変更によって上層の論理差分が変わった場合は、`pr-review-response-flow`の規則に従って上層を再評価する。

下位 flow が作成した pending review は submit しない。
pending review URL と対象 pull request を人間待ちとして記録し、再実行時に submit 済みかを取得する。
未解決 thread も自動で resolve せず、人間の操作後に再取得する。

## merge を待つ

pull request の merge 可否を推測しない。
Draft 状態、required review、必須 check、未解決 thread、base pull request の merge、head OID を再取得する。

条件を満たした pull request は merge 待ちとして人間へ提示する。
stack では bottom の merge を確認してから次の pull request の base、head、差分、check を再検証する。
merge 後の branch 更新や base 変更により保存済み identity と差が出た場合は、その差を解消する下位 flow を選び直す。

## 完了する

root ticket に対応する全実装 ticket を relation 付きで再取得する。
各実装 ticket に対応する pull request が一件だけあり、すべて merge 済みで、stack 順序と merge 先が承認済み設計に一致することを確認する。
範囲外 blocker は実装完了の件数へ含めない。

全条件を満たした場合だけ`workflow-state`を complete する。
root ticket の完了状態への変更は、人間が承認した別の ticket 操作がない限り行わない。

## 停止条件

次の場合は状態を保持して停止する。

- root ticket を一件に確定できない。
- ticket の親をたどれず、root 配下か判定できない。
- 承認済み設計、成果物 digest、ticket graph のいずれかが一致しない。
- root 配下でない ticket の実装が必要になる。
- 範囲外 blocker が未完了である。
- ticket、branch、pull request、stack の対応が一件に定まらない。
- 下位 flow が人間の判断または外部操作を待っている。
- review submit、thread resolve、merge が必要である。
- 再取得した外部状態が保存済み identity と異なる。

構造検査と再開シナリオは[検証記録](references/validation.md)に残す。
