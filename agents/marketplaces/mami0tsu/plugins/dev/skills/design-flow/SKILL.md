---
name: design-flow
description: 生の要求または既存 ticket から、保存先を確定し、dig と専門 sub-agent の独立検証を経て、人間が承認した設計、受け入れ条件、PR 分割、ticket 関係、stack 順序を作る。実装前の設計、単一 PR または複数 PR の計画、未対応 Wiki への設計保存が必要なときに使う。
---

# Design Flow

生の要求または既存 ticket を、実装へ渡せる承認済み設計に変換する。
承認済み設計が入力された場合も、正本と承認範囲を照合してから再利用する。

## 入力を確定する

ticket URL がある場合は、[ticket-usage](../ticket-usage/SKILL.md) で本文、状態、親、block 関係、正本 URL を取得する。
生の要求だけがある場合は、要求を設計の入力にする。

既存の承認済み設計を使う場合は、正本 URL、承認者が確定した範囲、承認後の変更の有無を確認する。
いずれかを確認できなければ未承認として扱う。

呼び出し元が [workflow-state](../workflow-state/SKILL.md) の workflow ID を渡した場合は、識別情報を照合して同じ状態を再開する。
下位 flow として `design-flow` namespace だけを更新し、別のトップレベル状態を作らない。
外部 object は URL、ID、commit OID、判断結果だけで参照し、要求本文、設計本文、review 本文は保存しない。

## 正本を選ぶ

設計を始める前に、保存先候補と根拠を提示して人間に1つ選んでもらう。

- プロダクトのコード、データ、外部 interface を規定する設計は repository を第一候補にする。
- 開発手順、ticket 構成、review 運用を規定する設計は Linear を第一候補にする。
- 既存の外部 Wiki が正本である場合は、その Wiki を候補にできる。

初期対応する書き込み先は repository と Linear に限定する。
未対応 Wiki が選ばれた場合は、承認済み本文を人間へ渡して停止する。
人間が保存した正本 URL を受け取ったら、同じ workflow state と本文を照合して再開する。

## 設計を作る

承認済み設計がない場合は `$dig` を必ず使う。
各質問の前に repository と ticket の関連箇所を調べ、調査で確定できる内容を人間へ聞かない。

設計は [成果物 contract](references/artifact-contract.md) のすべての field を満たすまで具体化する。
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
人間には少なくとも、設計判断、受け入れ条件、PR 分割、親子関係、block 関係、stack 順序、repository の設計文書を含める PR を承認してもらう。

訂正または未解決の疑問が返った場合は `dig`へ戻し、同じ sub-agent で再検証する。
明示的な承認が得られるまで ticket の作成、分割、更新へ進まない。

## 正本へ保存する

repository が正本の場合は、設計文書を単一 PR または stack 最下層の PR にだけ含める。
Linear が正本の場合は [ticket-usage](../ticket-usage/SKILL.md) で、書き込み直前の状態を確認し、書き込み後に検証する。

workflow ID を受け取っている場合は、保存後に正本 URL、承認済み成果物の種別、PR 数、設計文書を含める PR を `design-flow` namespace へ記録する。
後続の `ticket-flow` には正本 URLと承認済み成果物を渡し、設計を再解釈させない。

## 停止条件

次の場合は状態を保持して停止する。

- 保存先を人間が確定していない。
- 既存設計の正本または承認範囲を確認できない。
- `dig`に未決事項が残っている。
- 必要な sub-agent 検証を完了できない。
- actionable finding が残っている。
- 人間が成果物全体を承認していない。
- 未対応 Wiki への保存後 URL を確認できない。

構造検査とシナリオ試験の結果は [検証記録](references/validation.md) に残す。
