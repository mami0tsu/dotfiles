---
name: inspect
description: リポジトリを調査して改善点を見つけ、Issue の候補を返す。
compatibility: Requires Bash, CUE (cue), GitHub CLI (gh), and Knap (knap).
allowed-tools: >-
  Read
  Write
  Glob
  Grep
  Skill(doc:japanese-tech-writing)
  Skill(doc:cognitive-rhythm-writing)
  Skill(yomiyasu)
  Bash(bash */skills/inspect/scripts/check-config.sh *)
  Bash(bash */skills/inspect/scripts/search-issues.sh *)
  Bash(bash */skills/inspect/scripts/render-issue.sh *)
  Bash(bash */hooks/check-inspect-issues.sh *)
---

# Inspect

## 入力

| 項目 | 内容 |
| --- | --- |
| `factory.json` | loop から渡された設定ファイルの絶対パス |
| リポジトリ | loop から渡されたリポジトリの URL と絶対パス |
| レビュー結果 | loop から渡された Issue 候補と指摘 |
| 実行内容 | 調査の可否の確認、または候補の調査 |

## 出力

| 成果物 | 内容 |
| --- | --- |
| 調査の可否 | Issue の上限に基づく新規候補の調査の可否 |
| Issue の候補 | 題名、本文ファイルの絶対パスと調査の根拠の一覧 |

## 手順

loop からレビュー結果を受け取った場合は、[調査結果の修正](#調査結果の修正)から実行する。

### 設定の確認

1. [check-config.sh](scripts/check-config.sh) に設定ファイルの絶対パスを渡して実行し、必要な設定を確認する。
   設定が存在しない、不正または不足している場合は、設定パスと不足項目を loop に返して終了する。
   調査範囲の指定がなければリポジトリ全体を対象とする。

### 調査の可否の確認

調査の可否の確認を指定された場合は、この節を実行する。

1. `maxOpenIssues` が指定されている場合は、[上限確認フック](../../hooks/check-inspect-issues.sh) に設定ファイルの絶対パスを渡して実行する。
   終了コードが 2 の場合は新規候補の調査を見送る。
   件数を取得できない場合は理由を返して終了する。
   上限未満または上限が指定されていない場合は新規候補の調査を可能とする。
1. 調査の可否を loop に返して終了する。

### Issue 候補の作成

1. 準備されたリポジトリのパスを使い、設定された範囲のコードやドキュメントを調査して改善点を探す。
   根拠となる箇所はパーマネントリンクで示す。
1. 改善案の背景と根拠を確認し、登録に足る候補を選ぶ。
1. [search-issues.sh](scripts/search-issues.sh) に設定ファイルの絶対パスと候補を表す検索語を渡して実行し、管理先の既存 Issue と照合する。
   重複する候補は登録しない。
1. 候補ごとに[テンプレート](assets/issue_template.md)の各項目を JSON に記録する。
   根拠となる一次情報は該当する文章中のリンクか脚注で示す。
   表を使う対象以外の項目では、同列の情報を比較または列挙するときは箇条書きで示す。
1. [render-issue.sh](scripts/render-issue.sh) に JSON ファイルとレンダリング結果の保存先の絶対パスを渡して実行する。
   用途に合う重要な情報には [GitHub のアラート](https://docs.github.com/ja/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts)を使う。
1. レンダリングした本文を japanese-tech-writing、cognitive-rhythm-writing、yomiyasu の各スキルで推敲する。
   内容とリンクを保ち、推敲後の本文をレンダリング結果のファイルに保存する。
1. 本文の末尾に、使用中のエージェント名とモデル名を入れた `Written by <Agent Name> (<Model Name>)` を記載する。
   モデル名を確認できない場合は、推測せずエージェント名だけを記載する。
1. 候補ごとの題名、本文ファイルの絶対パスと調査の根拠を一覧で loop に返す。
   候補がない場合は空の一覧を返す。

### 調査結果の修正

1. レビューの指摘に従って Issue 候補を修正し、loop に返して終了する。
   修正できない場合は保留する。
