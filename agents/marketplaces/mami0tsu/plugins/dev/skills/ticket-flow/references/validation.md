# 検証記録

2026-08-23 に検証した。

## 構造検査

`claude plugin validate agents/marketplaces/mami0tsu/plugins/dev --strict`で、plugin schema、skill の frontmatter と resource 構造を検証した。
`git diff --check`で差分の空白エラーを検査した。

## 単一 PR

既存 root ticket を参照する一件の PR を入力した。
root ticket を実装 ticket として更新し、子 ticket を作らないことを確認した。

root ticket を`proposal:root`とする場合も試した。
成果物内の container、title、description、assignee、state だけで root ticket を一件作成し、その正本 ID を PR の ticket 参照へ使うことを確認した。
作成後に branch と base を具体化した最終 description へ更新し、受け入れ条件と正本参照を再取得本文から検証した。

ticket system の`proposal:root`を正本にする場合も試した。
作成前は承認済み root description の digest を照合し、作成と ID 保存の直後に正本 description を再取得した。
同じ root を実装 ticket として使う単一 PR では正本本文を更新せず、具体化済み branch と base を workflow state と反映結果に記録した。

## 複数 PR

root 配下に三件の PR を置き、二件目と三件目が直前の PR に block される成果物を入力した。
各 ticket の作成と正本 ID の保存を先に完了し、全 ID の解決後に parent と block 関係を確定した。
各実装 ticket が一つの PR、branch、base と対応することを確認した。

成果物外 ticket への既存 blocks も入力した。
成果物内の`blocked_by`から導出できる逆辺だけを検証し、未指定の blocks を保持することを確認した。

全 ID の保存後、各 ticket の branch と base を具体化した。
最終 description の更新前後の digest を保存し、更新直後の中断から再開して同じ本文を再書き込みしないことを確認した。

repository を正本にした場合は、`includes_design_document: true`の一件だけが設計文書の path と digest を持つことを確認した。
その ticket が stack の最下層でない入力は、provider への書き込み前に停止した。

## 中断からの再開

ticket 作成後、次の作成前に中断するシナリオを試した。
保存済み ID がある operation は正本 ID で再取得し、不足分だけを更新した。
本文は保存せず、その SHA-256、担当者、状態、relation ID 集合を pre-state として stale 判定できることを確認した。

作成成功後に ID を保存できたか判断できないシナリオでは再作成しなかった。
root 直下の候補を提示し、人間が operation key と正本 ID を対応づけるまで停止した。

## provider の制約

複数 parent、未解決の blocker、作成と relation 設定を一回で表現できない provider を入力した。
近い relation への置換や部分的な書き込みを行わず、`unsupported-relation`または`unsupported-field`として停止した。

## 正本の変更

repository blob、ticket description、Wiki 本文を正本種別ごとに再取得し、UTF-8 本文の SHA-256を成果物と照合した。
承認後に本文が変わった正本と、取得できない revision は、ticket への書き込み前に停止した。
ticket system の正本と実装 ticket が同一の場合は、完了時にも正本本文の digest が変わっていないことを確認した。
