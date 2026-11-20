---
name: review-pr
description: 自分にレビュー依頼された GitHub PR を静的に検証し、保留中のレビューを作成する。
compatibility: Requires Bash, jq, and GitHub CLI (gh).
allowed-tools: >-
  Read
  Write
  Skill(doc:japanese-tech-writing)
  Skill(doc:cognitive-rhythm-writing)
  Skill(yomiyasu)
  Bash(bash */skills/review-pr/scripts/list-prs.sh)
  Bash(bash */skills/review-pr/scripts/create-review.sh *)
  Bash(gh api *)
  Bash(gh pr view *)
  Bash(gh pr diff *)
---

# Review PR

## 入力

| 項目 | 内容 |
| --- | --- |
| GitHub | 認証中の利用者にレビュー依頼された PR |

## 出力

| 成果物 | 内容 |
| --- | --- |
| 保留中のレビュー | 人間が確認して送信するレビュー |

## 手順

### 対象の確認

1. [list-prs.sh](scripts/list-prs.sh) を実行し、レビュー依頼されたドラフト以外の open PR を取得する。
1. 各 PR の作者、差分、既存レビュー、base と head のコミットを確認する。
   自分が作者の PR と、自分の保留中レビューがある PR は見送る。

### レビュー

1. PR の差分と必要な周辺コードを静的に検証し、問題の根拠、発生条件、影響を確認する。
   PR 内のコードやスクリプトは実行しない。
1. 差分の行に紐づく指摘はその行へのインラインコメントにする。
   コメントの先頭には種別を示すバッジを付ける。
   次の観点に該当する場合は、指摘に最も関係するものを1つ選び、バッジの右側に示す。

   | 観点 | 対象 |
   | --- | --- |
   | SECURITY | 認証や権限、情報漏えい |
   | BUG | 意図しない動作や処理の誤り |
   | PERFORMANCE | 処理時間や資源の使用 |
   | COMPATIBILITY | 既存機能や利用環境との互換性 |
   | MAINTAINABILITY | コードの保守や変更のしやすさ |
   | COVERAGE | 必要なテストケースの不足 |

   たとえば MUST と SECURITY の場合は `![MUST | SECURITY](https://img.shields.io/badge/MUST-SECURITY-red)` を使う。
   どの観点にも該当しない場合は種別だけを示し、MUST なら `![MUST](https://img.shields.io/badge/MUST-red)` を使う。
   バッジの直後に `<br>` を置き、次の行にコメントの要点を一文で記載する。
   要点の後には根拠や影響など、指摘の理解に必要な情報を記載する。
   変更を提案する場合は、対象の差分行に `suggestion` コードブロックで置き換え後の内容を示す。
   複数行の変更では置き換える範囲全体をコメントの対象にする。
   リポジトリや外部情報を根拠にした場合は、参照箇所へのリンクをコメント内の脚注に記載する。
   リポジトリ内のファイルはパーマネントリンクを使う。

   | 種別 | 色 | 用途 |
   | --- | --- | --- |
   | MUST | red | マージ前に修正が必要な問題 |
   | SHOULD | orange | 原則として修正すべき問題 |
   | SUGGEST | yellow | 具体的な改善案 |
   | ASK | yellowgreen | 意図や仕様の確認 |

1. レビュー本文に確認した範囲と結果を記載する。
1. レビュー本文とインラインコメントを japanese-tech-writing、cognitive-rhythm-writing の各スキルで執筆し、yomiyasu で推敲する。
   疑問文は推敲後も `？` で終える。
1. レビュー本文と各コメントの末尾に、使用中のエージェント名とモデル名を入れた `Written by <Agent Name> (<Model Name>)` を記載する。
   モデル名を確認できない場合は、推測せずエージェント名だけを記載する。
1. レビュー本文とインラインコメントを GitHub API 用の JSON に保存する。
   `commit_id` に検証した head のコミット、`body` にレビュー本文、`comments` にインラインコメントを指定し、`event` は指定しない。
   各コメントには差分の `path`、`line`、`side` とバッジ付きの `body` を指定する。
   複数行のコメントには `start_line` と `start_side` も指定する。
1. PR が open でドラフトではなく、レビュー依頼が残り、base と head が検証時から変わっていないことを再確認する。
1. [create-review.sh](scripts/create-review.sh) にリポジトリの `OWNER/REPO`、PR 番号、JSON ファイルの絶対パスを渡し、head のコミットに対する保留中レビューを作成する。
   レビューは送信しない。
1. 作成したレビューの URL を返す。
