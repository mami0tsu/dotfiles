# 検証記録

2026-08-23 に検証した。

## 構造検査

`quick_validate.py`で、skill 名、frontmatter、description の形式を検証した。
textlint、yamllint、JSON parser、`git diff --check`で、Markdown、YAML、plugin manifest、差分を検証した。

## 単一 PR

dev plugin の README に利用例を追加する要求を入力した。
sub-agent は repository と Linear を保存先候補として提示し、repository を推奨した。
保存先が未承認のため、`dig`、設計案、ticket 更新へ進まず停止した。

repository の承認後に生成する成果物は、`pull_requests`を1件だけ持つ。
その項目は root ticket、default branch、設計文書を含む PR に対応する。

## 複数 PR

DB schema、API、frontend を段階的に変更する要求を入力した。
sub-agent はコード、データ、外部 interface を規定するため repository を推奨し、Linear も候補として提示した。
保存先が未承認のため、PR 分割案を先に作らず停止した。

repository の承認後に生成する成果物は、各 PR の目的、受け入れ条件、親 ticket、block 関係、base branch を持つ。
設計文書は stack 最下層の PR だけに置く。

## 未対応 Wiki

未対応 Wiki が選ばれた場合は、承認済み本文を渡して保存を人間へ委ねる。
保存後の正本 URL を確認するまで、ticket の作成、分割、更新へ進まない。
