---
name: ticket-flow
description: 承認済み design-flow 成果物を、一つの PR と一つの実装 ticket が対応する構成へ反映し、親子関係、block 関係、branch、正本を含む ticket を確定する。
---

# Ticket Flow

承認済み設計の ticket 案を、再解釈せず provider の正本へ反映する。
1つの実装 ticket は、1つの branch、worktree、PR に対応する。

## 入力を照合する

[design-flow の成果物 contract](../design-flow/references/artifact-contract.md) を満たす承認済み成果物、正本の識別情報、成果物と正本本文の SHA-256を受け取る。
`unresolved`が空であり、`artifact_sha256`と`canonical.content_sha256`が design-flow の完了記録または承認記録と一致することを確認する。
成果物の field を補完したり、PR 境界、受け入れ条件、親子関係、block 関係、stack 順序を再解釈したりしない。

正本を現在の識別情報から再取得する。
repository では`canonical.revision`の`canonical.path`にある blob、ticket system では`canonical.target_ref`の description、Wiki では`canonical.url`と revision が指す本文を取得する。
取得した UTF-8 本文の SHA-256が`canonical.content_sha256`と一致することを確認する。
正本を再取得できない場合、revision または path が実在しない場合、digest が異なる場合は反映計画へ進まない。

ticket system の`canonical.target_ref`が`proposal:root`の場合だけ、作成前の再取得対象は存在しない。
この場合は承認済み`root_ticket.description`の UTF-8 本文の SHA-256を`canonical.content_sha256`と照合する。
root ticket の作成と正本 ID の保存直後に description を再取得し、同じ digest と一致するまで他の provider 書き込みへ進まない。

既存 root ticket を成果物が参照する場合は、[ticket-usage](../ticket-usage/SKILL.md) で本文、担当者、状態、親、block 関係、正本 URL を取得する。
`proposal:root`の場合は、成果物の`root_ticket`にある title、description、container、assignee、state を作成案として人間へ提示する。
いずれかの field が未定義なら補完せず停止する。
root ticket 案を承認されるまで provider へ書き込まない。

呼び出し元の [workflow-state](../workflow-state/SKILL.md) workflow ID を必須にする。
同じ状態の`ticket-flow` namespace だけを更新し、別のトップレベル状態を作らない。
成果物の SHA-256、root ticket ID、PR key と ticket ID の対応、正規化した pre-state、作成と更新の完了結果だけを保存する。
ticket 本文、設計本文、review 本文は保存しない。

## 反映計画を確定する

provider へ書き込む前に、次の反映計画を成果物から機械的に作り、人間へ提示する。

- 作成または更新する root ticket
- PR key ごとの実装 ticket、受け入れ条件、branch、base
- 各 ticket の parent、blockedBy、成果物内の`blocked_by`から導出できる blocks の期待集合
- repository の設計文書を含める ticket
- 実行する書き込み順序

単一 PR では、root ticket 自体を実装 ticket として使う。
既存 root ticket に成果物の受け入れ条件、branch、正本参照を反映し、子 ticket を作らない。
`proposal:root`では root ticket を一件だけ作成し、その ID を PR の`ticket_ref`にも使う。

複数 PR では、root 配下に`pull_requests`の項目と同数の実装 ticket を作る。
各 ticket の description には、その PR の purpose、受け入れ条件と verification、branch または branch template、base を記録する。
`parent_ref`を作業範囲の包含として、`blocked_by`を実行順序として別々に反映する。

description は、purpose、acceptance criteria、branch、base、canonical の順に固定した Markdown から生成する。
acceptance criteria は criterion と verification の組を成果物の順序どおりに記録する。
canonical には正本 URL または repository path、revision、正本本文の SHA-256を記録する。
この形式以外の説明を補わない。

`canonical.kind`が`repository`の場合は、`includes_design_document: true`の PR が一件だけ存在することを確認する。
その PR に対応する ticket の description へ、承認済み path、正本本文の SHA-256、設計文書をこの PR に含めることを記録する。
stack ではこの ticket が最下層でなければ停止する。
ticket system または Wiki が正本の場合は、すべての`includes_design_document`が`false`であることを確認する。

## 書き込み前の状態を保存する

作成予定の各 ticket に、安定した operation key を`root`または`pull_requests[].key`から割り当てる。
operation key、期待する現在値、期待する作成後の graph を`ticket-flow` namespace へ保存してから最初の provider 書き込みへ進む。
pre-state は description の UTF-8 byte 列の SHA-256、assignee ID、status の name と type、parent ID、blockedBy ID 集合、管理対象の blocks ID 集合へ正規化する。
本文そのものは保存しない。

再開時は、保存済みの成果物 SHA-256が入力と一致することを確認する。
保存済み ID がある operation は、その ID を[ticket-usage](../ticket-usage/SKILL.md) で再取得し、期待値との差分だけを更新する。
保存済み ID がない operation で、前回の作成が成功した可能性を否定できない場合は再作成しない。
root の候補、または root 直下の子 ticket を列挙し、operation key と一件を人間に対応づけてもらう。
title の一致だけで作成済み ticket を選ばない。

## ticket graph を反映する

root ticket が proposal の場合は最初に作成する。
作成 response の正本 ID と URL を、他の provider 書き込みより先に workflow state へ保存する。
作成後は relation を含めて再取得し、担当者、状態、本文、正本 URL を期待値と比較する。

複数 PR の実装 ticket は成果物の順に一件ずつ作成する。
作成時は parent と、すでに正本 ID を解決できた blockedBy だけを同じ provider 操作へ渡す。
未作成 ticket の ID を必要とする blocks は作成時に渡さない。
各作成 response の正本 ID と URL を、次の ticket 作成より先に保存する。
作成後は relation を含めて再取得し、本文、担当者、状態、parent、作成時点の blockedBy、正本 URL を検証する。

すべての正本 ID を保存した後、各 ticket の parent と blockedBy を成果物の期待集合へ一致させる。
成果物内の blockedBy の逆辺として導出できる blocks だけを管理対象にする。
成果物に記載されていない既存 blocks と、成果物外 ticket への blocks は保持し、削除しない。
relation 更新後にすべての ticket を再取得し、parent、blockedBy、管理対象の blocks を検証する。

既存 ticket の更新前には対象を再取得する。
担当者、状態、本文の SHA-256、parent、blockedBy、管理対象の blocks の現在値が反映計画の正規化済み pre-state と異なる場合は`stale-ticket`として停止する。
relation は現在集合と期待集合の差分だけを[ticket-usage](../ticket-usage/SKILL.md)で更新する。
blockedBy の削除は反映計画へ明示し、人間が graph 全体を承認した場合だけ実行する。
成果物から期待値を導出できない既存 blocks は更新対象に含めない。

provider が要求された field または relation を1回の操作で表現できない場合は、近い構成へ置き換えず、書き込み前に停止する。
書き込み後の再取得結果が期待値と異なる場合は`partial-write`として停止し、自動 rollback を試みない。

## 参照を具体化する

すべての作成 ID を保存した後、成果物の proposal 参照を正本 ID へ対応づける。
`branch_template`の`{ticket_id}`は対応する正本 ID へ一度だけ置き換え、完全な branch 名として記録する。
`base_ref: pr:<key>`は、対応する blocker ticket の具体化済み branch へ解決する。

具体化した branch と base を使い、固定形式から各実装 ticket の最終 description を生成する。
ただし、ticket system の正本 object と実装 ticket が同一の場合は、承認済み設計の description を変更しない。
その ticket では成果物内の purpose、acceptance criteria、branch または branch template、base を検証し、具体化した branch と base は workflow state と反映結果に記録する。
正本 description の SHA-256が`canonical.content_sha256`のままであることを完了時にも確認する。
正本ではない単一 PR の`proposal:root`は、root ticket を作成した後に最終 description の更新対象へ含める。
各更新前に、現在 description の SHA-256と期待する最終 description の SHA-256を pending operation として workflow state へ保存する。
再開時は現在 description を再取得し、pre-state digest なら未更新、期待する digest なら更新済み、どちらとも異なる場合は`stale-ticket`として扱う。
未更新の場合だけ最終 description へ更新し、再取得した本文の SHA-256、具体化済み branch、base、受け入れ条件、正本参照を検証する。

具体化した PR key、ticket ID、ticket URL、branch、base、parent、blockedBy、blocks、`includes_design_document`を反映結果として返す。
承認済み成果物自体は書き換えず、proposal と正本 ID の対応を別の結果として保持する。

## 完了する

root とすべての実装 ticket を relation 付きで再取得する。
1つの PR と1つの実装 ticket が対応し、単一 PR に子 ticket がなく、複数 PR の各 ticket に具体化済み branch、base、受け入れ条件、blocker の期待集合があり、設計文書を含める ticket が明示されていることを確認する。
ticket system の正本と同一の実装 ticket では、正本本文が不変であり、具体化済み branch と base が workflow state の対応結果にあることを確認する。

検証後に、成果物の SHA-256、root ticket ID、PR key と ticket ID の対応、具体化済み branch と base、graph の検証結果を`ticket-flow` namespace へ記録する。
呼び出し元へ正本 URL と具体化結果を返す。
トップレベル workflow の状態は完了しない。

## 停止条件

次の場合は状態を保持して停止する。

- 成果物、正本、承認範囲、2つの SHA-256のいずれかを照合できない。
- workflow ID がない、または保存済み workflow の識別情報と一致しない。
- root ticket 案または反映計画が人間に承認されていない。
- PR 境界、ticket 関係、stack 順序を補完または再解釈しなければ反映できない。
- repository の設計文書を含める PR が一件に決まらない、または stack の最下層ではない。
- 作成成功後に正本 ID を保存できたか判断できない。
- provider が要求された field または relation を表現できない。
- 書き込み前の ticket が反映計画の pre-state と異なる。
- 書き込み後の ticket graph が期待値と異なる。

構造検査とシナリオ試験の結果は[検証記録](references/validation.md)に残す。
