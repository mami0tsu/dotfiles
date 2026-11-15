---
name: research
description: 設定されたリポジトリを調査し、改善案を GitHub Issue として登録する。
compatibility: Requires Bash, CUE (cue), Git, ghq, GitHub CLI (gh), and Knap (knap).
allowed-tools: >-
  Read
  Write
  Glob
  Grep
  Skill(factory:init)
  Skill(doc:japanese-tech-writing)
  Skill(doc:cognitive-rhythm-writing)
  Skill(yomiyasu)
  Bash(bash */skills/research/scripts/check-config.sh *)
  Bash(bash */skills/research/scripts/prepare-repository.sh *)
  Bash(bash */skills/research/scripts/search-issues.sh *)
  Bash(bash */skills/research/scripts/render-issue.sh *)
  Bash(bash */skills/research/scripts/create-issue.sh *)
---

# Research

## 入力

| 項目 | 内容 |
| --- | --- |
| `factory.json` | 調査対象とアイデアの管理先を指定した設定 |

## 出力

| 成果物 | 内容 |
| --- | --- |
| GitHub Issue | [テンプレート](assets/issue_template.md)に従って登録した改善案 |

## 手順

### 設定の確認

1. 作業ディレクトリとその配下から `factory.json` を探す。
   複数ある場合は対象を確認する。
1. 設定が存在しない場合は、作業ディレクトリの `factory.json` を作成先として [init スキル](../init/SKILL.md)を呼び出す。
1. [check-config.sh](scripts/check-config.sh) に設定ファイルの絶対パスを渡して実行し、research に必要な設定を確認する。
1. 設定が不正または不足している場合は、同じパスと不足項目を指定して init スキルを呼び出し、再び設定を確認する。
   調査範囲の指定がなければリポジトリ全体を対象とする。

### リポジトリの調査

1. 各リポジトリについて [prepare-repository.sh](scripts/prepare-repository.sh) を実行し、ghq で取得してデフォルトブランチを最新化する。
   引数には設定ファイルの絶対パスと `repositories` の対象の配列番号を渡す。
1. スクリプトが返したリポジトリのパスを使い、設定された範囲のコードやドキュメントを調査して改善点を探す。
   根拠となる箇所はパーマネントリンクで示す。
1. 改善案の背景と根拠を確認し、登録に足る候補を選ぶ。

### Issue の登録

1. [search-issues.sh](scripts/search-issues.sh) に設定ファイルの絶対パスと候補を表す検索語を渡して実行し、管理先の既存 Issue と照合する。
   重複する候補は登録しない。
1. 候補ごとにテンプレートの各項目を JSON に記録する。
   根拠となる一次情報は該当する文章中のリンクか脚注で示す。
   表を使う対象以外の項目では、同列の情報を比較または列挙するときは箇条書きで示す。
1. [render-issue.sh](scripts/render-issue.sh) に JSON ファイルとレンダリング結果の保存先の絶対パスを渡して実行する。
1. レンダリングした本文を japanese-tech-writing、cognitive-rhythm-writing、yomiyasu の各スキルで推敲する。
   内容とリンクを保ち、推敲後の本文をレンダリング結果のファイルに保存する。
1. テンプレートのコメントにある `labels` を読み取る。
1. [create-issue.sh](scripts/create-issue.sh) に設定ファイルの絶対パス、題名、レンダリング結果の絶対パス、ラベルを渡して実行する。
1. 登録した Issue の URL を返す。
