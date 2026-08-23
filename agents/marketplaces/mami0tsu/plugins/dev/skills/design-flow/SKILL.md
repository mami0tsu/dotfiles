---
name: design-flow
description: 生の要求または既存 ticket から、保存先を確定し、dig と専門 sub-agent の独立検証を経て、人間が承認した設計、受け入れ条件、PR 分割、ticket 関係、stack 順序を作る。実装前の設計、単一 PR または複数 PR の計画、未対応 Wiki への設計保存が必要なときに使う。
---

# Design Flow

生の要求または既存 ticket を、実装へ渡せる承認済み設計に変換する。
承認済み設計が入力された場合も、正本と承認範囲を照合してから再利用する。

## 入力を確定する

ticket URL がある場合は、[ticket-usage](../ticket-usage/SKILL.md) で本文、状態、親、block 関係、正本 URL を取得する。
生の要求だけがある場合は、要求を設計の入力にし、root ticket の作成案を成果物に含める。

既存の承認済み設計を使う場合は、正本 URL、承認者が確定した範囲、承認後の変更の有無を確認する。
いずれかを確認できなければ未承認として扱う。

呼び出し元が [workflow-state](../workflow-state/SKILL.md) の workflow ID を渡した場合は、識別情報を照合して同じ状態を再開する。
下位 flow として `design-flow` namespace だけを更新し、別のトップレベル状態を作らない。
外部 object は URL、ID、commit OID、判断結果、承認済み成果物と正本本文の SHA-256だけで参照し、要求本文、設計本文、review 本文は保存しない。

## 正本を選ぶ

設計を始める前に、保存先候補と根拠を提示して人間に1つ選んでもらう。

- プロダクトのコード、データ、外部 interface を規定する設計は repository を第一候補にする。
- 開発手順、ticket 構成、review 運用を規定する設計は、入力 ticket を管理する system を第一候補にする。
- 既存の外部 Wiki が正本である場合は、その Wiki を候補にできる。

repository を選ぶ場合は、既存文書との関係、対象 path、設計文書を含める PR を同時に確定する。

Agent が直接書き込める保存先は、repository と ticket system に限る。
ticket system への書き込みには、[ticket-usage](../ticket-usage/SKILL.md) の provider adapter が本文更新をサポートしていることを必要とする。
未対応 Wiki が選ばれた場合は、承認済み本文を人間へ渡して停止する。
人間が保存した正本 URL を受け取ったら、同じ workflow state と本文を照合して再開する。

## 設計を作る

承認済み設計がない場合は、実行環境で利用できる `dig` skill を必ず使う。
各質問の前に repository と ticket の関連箇所を調べ、調査で確定できる内容を人間へ聞かない。

設計は [成果物 contract](references/artifact-contract.md) のすべての field を満たすまで具体化する。
root ticket を提案する場合は、title だけでなく、container、description、assignee、state も承認対象として確定する。
未決事項、相互に矛盾する受け入れ条件、根拠のない PR 境界が残っている間は検証へ進まない。

## 独立に検証する

実行環境に応じて [Codex adapter](references/codex.md) または [Claude Code adapter](references/claude-code.md) を読む。
どちらにも該当しない場合、または独立した sub-agent を2つ以上利用できない場合は停止する。

設計案を2つまたは3つの専門 sub-agent へ同時に渡す。
観点は設計に合わせて分け、少なくとも次を網羅する。

- 要求、受け入れ条件、設計判断の整合性
- component 境界、移行、失敗時の挙動、回帰リスク
- PR 分割、ticket 関係、block 関係、stack 順序の実行可能性

各 sub-agent には入力要求、設計案、関連する repository と ticket の事実だけを渡す。
作成者の結論、期待する回答、他の sub-agent の finding は渡さない。

finding は根拠と再検証条件を添えて重複排除する。
誤検知または根拠不足だけを除外し、未解決の finding が一件でもあれば `dig`へ戻す。
修正後は同じ sub-agent に新しい設計案を渡し、finding がなくなるまで繰り返す。

## 人間の承認を得る

検証済み成果物を [成果物 contract](references/artifact-contract.md) の形で提示する。
人間には正本へ保存する Markdown 本文も提示する。
少なくとも、設計判断、受け入れ条件と検証方法、PR 分割、親子関係、block 関係、branch、base、stack 順序、正本本文を承認してもらう。
repository を正本にする場合は、対象 path と設計文書を含める PR も承認対象にする。

訂正または未解決の疑問が返った場合は `dig`へ戻し、同じ sub-agent で再検証する。
明示的な承認が得られるまで ticket の作成、分割、更新へ進まない。

## 保存を準備する

承認前に正本へ保存する Markdown 本文を確定し、[成果物 contract](references/artifact-contract.md) の除外規則に従って成果物の SHA-256を求める。
まず [digest helper](scripts/artifact_digest.py) の`--compute`で正本本文と成果物の SHA-256を計算し、成果物へ設定する。
次に`--compute`なしで同じ helper を実行し、成果物の宣言値と再計算値が一致することを検証する。

Agent が可変な外部正本へ書き込む場合は、provider を問わず workflow ID を必須にする。
正本種別、対象 object と field、`expected_pre_content_sha256`、`desired_content_sha256`、成果物の SHA-256を pending operation として外部書き込み前に記録する。

既存 ticket が正本の場合は、承認済みの`target_ref`と`target_field`だけを [ticket-usage](../ticket-usage/SKILL.md) で更新する。
provider adapter が対象 field の取得と更新に対応しない場合は、未対応 Wiki と同じ人間保存の手順へ進む。
書き込み直前の本文 digest が pending operation の pre-state と一致しなければ停止する。
承認済み本文を保存した後に同じ対象を再取得する。
再取得した本文の SHA-256が承認済み正本本文と一致しなければ停止する。

生の要求で作成予定の root ticket を正本にする場合は、この flow では書き込まない。
`proposal:root`と`ticket-usage`共通 contract の`description`を保存先として成果物へ含め、後続の ticket 作成へ引き渡す。
作成後の URL と本文 digest を受け取ったら同じ成果物で再開し、正本を再取得して照合する。

repository が正本の場合、設計文書の書き込みはこの flow では行わない。
承認済み本文、対象 path、成果物と正本本文の SHA-256を、単一 PR または stack 最下層の実装計画へ含める。
後続 flow が対象 branch と worktree を確定し、書き込み前の path と base commit を照合してから文書を commit する。
commit 後に blob と正本本文の SHA-256を照合し、その commit の file URL を正本 URL にする。

未対応 Wiki では人間から保存後 URL を受け取り、本文を再取得できる場合は SHA-256を照合する。
本文を再取得できない場合は、保存者による本文一致の明示的な確認と、承認済み正本本文の SHA-256を要求する。
immutable revision だけでは完了扱いにしない。

再開時に pending operation がある場合は正本を再取得する。
分岐は [resume helper](scripts/resume_decision.py) と同じ判定にする。
現在本文が`desired_content_sha256`と一致する場合は書き込み済みと判断し、現在 revision を取得できる場合は`post_revision`として完了記録へ進む。
現在本文 digest が`expected_pre_content_sha256`のままなら未書き込みと判断し、書き込み直前に再取得して同じ digest であることを確認した後、承認済み本文だけを書き込む。
どちらにも一致しない場合は、再書き込みせず停止する。

workflow ID を受け取っている場合は、保存後に正本 URLまたは対象 repository path、正本 revision、成果物と正本本文の SHA-256、PR 数、設計文書を含める PR を `design-flow` namespace へ記録し、pending operation を完了扱いにする。

## 成果物を引き渡す

承認済み成果物、正本の識別情報、成果物と正本本文の SHA-256を呼び出し元へ返す。
この flow は ticket の作成、分割、状態、親子関係、block 関係を更新しない。
承認された既存 ticket の本文 field を正本として更新する場合だけ、保存手順の範囲で本文を更新する。
後続の ticket 操作には成果物を再解釈させず、root ticket 案、各 PR の ticket 参照、親子関係、block 関係をそのまま反映させる。

## 停止条件

次の場合は状態を保持して停止する。

- 保存先を人間が確定していない。
- 既存設計の正本または承認範囲を確認できない。
- `dig`に未決事項が残っている。
- 必要な sub-agent 検証を完了できない。
- actionable finding が残っている。
- 人間が成果物全体を承認していない。
- 未対応 Wiki への保存後 URL を確認できない。
- 正本本文の SHA-256を`canonical.content_sha256`と照合できない。
- 外部書き込みの成否が曖昧である。
- Agent が可変な外部正本を更新する workflow ID がない。

構造検査とシナリオ試験の結果は [検証記録](references/validation.md) に残す。
