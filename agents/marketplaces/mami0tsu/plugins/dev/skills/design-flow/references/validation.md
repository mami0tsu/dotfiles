# 検証記録

2026-08-23 に検証した。

## 構造検査

`quick_validate.py`で、skill 名、frontmatter、description の形式を検証した。
textlint、yamllint、JSON parser、`git diff --check`で、Markdown、YAML、plugin manifest、差分を検証した。
`test_artifact_digest.py`で、正本 identity の追記に対する安定性、正本本文 digest の拘束、不一致本文の拒否を検証した。

## runtime と provider の横断監査

development plugin と skills 配下を`rg -F '$dig'`で検索し、Codex 固有の呼び出し表記が残っていないことを確認した。
Codex と Claude Code の固有記述は、sub-agent の起動方法を分ける adapter 内だけに置いた。

特定の ticket service 名を design-flow 配下で検索し、正本種別、保存手順、成果物 contract、検証シナリオに残っていないことを確認した。
ticket system の取得と更新は`ticket-usage`の provider adapter に委譲し、成果物では共通 field の`description`だけを使う。
provider 固有の本文 field 名は adapter の外へ出さない。
durable pending state は provider を問わず、Agent が可変な外部正本へ書き込む場合に要求する。

## 単一 PR

dev plugin の README に利用例を追加する生の要求を入力した。
repository を正本に選び、専用の設計文書 path と1件の PR を指定した。

成果物は`proposal:root`、root ticket の作成情報、`branch_template`、`branch:default`、受け入れ条件ごとの検証方法を生成した。
初回検証では、ticket 作成前の branch 名と、構造化成果物と repository blob の digest が混同されていた。

branch を ticket ID 入り template とし、成果物と正本本文の digest を分けた。
同じ2つの sub-agent で再検証し、finding 0件で人間承認の境界まで到達した。

## 複数 PR

既存 root ticket 配下で、DB schema、API、frontend を3件の PR に分ける要求を入力した。
入力 ticket を管理する system を正本に選び、`db-schema`、`api`、`frontend`の順で stack を指定した。

成果物は各 PR に proposal ticket、親、block 関係、branch template、`base_ref`、検証方法を生成した。
独立検証で、API の failure contract、rolling compatibility、cross-component test、dual-read、dual-write、旧 API からの更新伝播が不足していると判明した。

`dig`へ戻り、expand-only migration、transactional dual-write、旧 column から新 column への trigger、failure code と UI の対応、version 付き fixture、stack 全体の E2E test を追加した。
同じ2つの sub-agent で再検証し、finding 0件で人間承認の境界まで到達した。

## 外部保存の再開

外部書き込み前に pending operation、`expected_pre_content_sha256`、`desired_content_sha256`を記録する。
外部書き込み後、状態更新前に中断した場合を3分岐で試験した。

- 現在本文が desired digest と一致する場合：再書き込みせず、取得できた現在 revision を post-revision として完了する。
- 現在本文 digest が pre-state と一致する場合：書き込み直前に再取得し、同じ digest なら承認済み本文だけを書き込む。
- どちらにも一致しない場合または取得不能の場合：再書き込みせず停止する。

## 未対応 Wiki

未対応 Wiki が選ばれた場合は、承認済み本文を渡して保存を人間へ委ねる。
保存後の URL、保存者による本文一致の確認、正本本文の digest を確認するまで、成果物を後続 flow へ渡さない。
immutable revision だけでは完了扱いにしない。
