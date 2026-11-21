---
name: create-pr
description: 変更内容を簡潔に説明する GitHub のドラフト PR を作成する。
compatibility: Requires Bash, Git, GitHub CLI (gh), and Knap (knap).
allowed-tools: >-
  Read
  Write
  Glob
  Grep
  Skill(doc:japanese-tech-writing)
  Skill(doc:cognitive-rhythm-writing)
  Skill(yomiyasu)
  Bash(git diff *)
  Bash(gh pr list *)
  Bash(bash */skills/create-pr/scripts/render-pr.sh *)
  Bash(bash */skills/create-pr/scripts/push-branch.sh *)
  Bash(bash */skills/create-pr/scripts/create-pr.sh *)
---

# Create PR

## 入力

| 項目 | 内容 |
| --- | --- |
| リポジトリ | ローカルのパスと PR の作成先 |
| ブランチ | コミット済みの変更元、push 先と取り込み先 |
| 検証結果 | テンプレートが求める場合に記載する実行結果 |

## 出力

| 成果物 | 内容 |
| --- | --- |
| GitHub PR | 変更内容を簡潔に説明したドラフト PR |

## 手順

### 本文の作成

1. 取り込み先との差分と検証結果を確認し、既存の PR がないか確認する。
   同じリポジトリと変更元、取り込み先の open PR があれば、[push-branch.sh](scripts/push-branch.sh) で変更元を push し、その PR の URL を返して終了する。
   対応する PR がクローズ済みまたはマージ済みの場合は保留する。
1. デフォルトブランチの `.github/pull_request_template.md` と `.github/PULL_REQUEST_TEMPLATE/` からテンプレートを探す。
   テンプレートが複数ある場合は変更内容に合うものを選び、選べなければ確認する。
1. テンプレートがある場合は、その構成と必須項目に従って Knap テンプレートを作る。
   テンプレートがない場合は、[既定のテンプレート](assets/pr_template.md)を使う。
1. テンプレートの各項目に入れる内容を JSON に記録する。
   背景、目的、内容と影響を簡潔に示し、コードコメントに書かれた内容や実装の細部は繰り返さない。
   レビューに必要な影響や未検証の事項は省かない。
   リポジトリのテンプレートが形式や内容を指定する場合は、その指定に従う。
1. [render-pr.sh](scripts/render-pr.sh) にテンプレート、JSON、本文の保存先の絶対パスを渡して実行する。
   用途に合う重要な情報には [GitHub のアラート](https://docs.github.com/ja/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts)を使う。
1. 本文を japanese-tech-writing、cognitive-rhythm-writing、yomiyasu の各スキルで推敲する。
   リポジトリのテンプレートの必須項目を満たすことを確認する。
1. 本文の末尾に、使用中のエージェント名とモデル名を入れた `Written by <Agent Name> (<Model Name>)` を記載する。
   モデル名を確認できない場合は、推測せずエージェント名だけを記載する。

### PR の作成

1. [push-branch.sh](scripts/push-branch.sh) にローカルリポジトリの絶対パス、push 先のリモート名、変更元のブランチ名を渡して実行する。
1. [create-pr.sh](scripts/create-pr.sh) にリポジトリの `OWNER/REPO`、取り込み先、変更元、題名、本文ファイルの絶対パスを渡して実行する。
1. 作成した PR の URL を返す。
