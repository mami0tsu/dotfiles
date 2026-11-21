---
name: respond
description: GitHub の Issue と PR に返信する。
compatibility: Requires Bash and GitHub CLI (gh).
allowed-tools: >-
  Read
  Write
  Skill(doc:japanese-tech-writing)
  Skill(doc:cognitive-rhythm-writing)
  Skill(yomiyasu)
  Bash(gh api *)
  Bash(gh issue view *)
  Bash(gh pr view *)
  Bash(bash */skills/respond/scripts/list-notifications.sh)
  Bash(bash */skills/respond/scripts/reply.sh *)
  Bash(bash */skills/respond/scripts/create-pending-review.sh *)
  Bash(bash */skills/respond/scripts/reply-review.sh *)
---

# Respond

## 入力

| 項目 | 内容 |
| --- | --- |
| GitHub | 認証中の利用者への Issue と PR の通知 |
| 追加調査結果 | loop から渡された Issue の URL とレビュー済みの調査結果 |

## 出力

| 成果物 | 内容 |
| --- | --- |
| コメント | Issue または PR への返信 |
| 保留中のレビュー | PR のインラインコメントへの未送信の返信 |

## 手順

### 対象の確認

1. loop から追加調査結果を受け取っていない場合は、[list-notifications.sh](scripts/list-notifications.sh) を実行し、Issue と PR の通知を取得する。
1. 通知から対象を探す場合は、本文とコメントを確認し、人間が投稿した返信の必要なコメントを選ぶ。
   PR のインラインレビューコメントも確認する。
   エージェントの署名がある自分の投稿と、すでに返信した指摘は除く。
   loop から追加調査結果を受け取った場合は、指定された Issue を対象とする。

### 返信

1. コメントの内容と関連する情報を確認し、回答を作成する。
   追加調査結果を受け取った場合は、その内容を回答に使う。
   スレッドに複数の指摘がある場合は、指摘ごとに回答を分ける。
   スレッド以外のコメントに含まれる指摘には、指摘事項と採否の表を示した後、各指摘への回答を列挙する。

   | 指摘事項 | 採否 |
   | --- | --- |

   採否は採用、見送り、保留から選ぶ。
   参考にした一次情報へのリンクを回答内の脚注に記載する。
   リポジトリ内のファイルはパーマネントリンクを使う。
   確認できない内容は推測せず、必要な情報を質問する。
   用途に合う重要な情報には [GitHub のアラート](https://docs.github.com/ja/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts)を使う。
1. 回答を japanese-tech-writing、cognitive-rhythm-writing、yomiyasu の各スキルで推敲する。
   疑問文は `？` で終える。
1. 回答の末尾に、使用中のエージェント名とモデル名を入れた `Written by <Agent Name> (<Model Name>)` を記載する。
   署名がある場合は重複して記載しない。
   モデル名を確認できない場合は、推測せずエージェント名だけを記載する。
1. 回答をファイルに保存する。
1. Issue と PR の通常コメントには、返信元のコメントがある場合はそのリンクを含め、[reply.sh](scripts/reply.sh) を実行する。
   引数にはリポジトリの `OWNER/REPO`、Issue または PR の番号、回答ファイルの絶対パスを渡す。
1. PR のインラインコメントへの返信を対象 PR の保留中レビューに追加する。
   既存の保留中レビューが自分の作成したものと特定できない場合は、そのレビューを変更せず保留する。
   保留中のレビューがない場合は [create-pending-review.sh](scripts/create-pending-review.sh) にリポジトリの `OWNER/REPO` と PR 番号を渡して作成する。
   指摘ごとに [reply-review.sh](scripts/reply-review.sh) に保留中レビューの ID、返信先のレビュースレッドの ID、回答ファイルの絶対パスを渡して実行する。
   レビューは送信しない。
1. 投稿したコメントまたは保留中レビューの URL を返す。
