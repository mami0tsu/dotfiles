---
name: dev-flow
description: レビュー済みのチケットや設計成果物を実装し、worktree、敵対的検証、difit review、Draft PR、振り返りまで完了させる開発フロー。チケットに沿って開発するときに使う。
---

# Development Flow

レビュー済みのチケットまたは設計成果物を入力にする。
入力が不足している場合は実装せず、`documentation` plugin で更新してレビューを受ける。

## 手順

1. default branch を更新する。
2. 専用 worktree と ticket ID を含む branch を用意する。
3. 入力成果物の範囲内で実装し、テストする。
4. サブエージェントに敵対的検証を依頼し、指摘が 0 件になるまで修正する。
5. `difit-review` で人間レビューを受け、コメントが 0 件になるまで修正する。
6. 変更を commit、push し、`gh-usage` で Draft PR を作成する。
7. `.agent/retrospectives/<ticket-id>.md` に振り返りを記録する。

worktree を再利用する前に remote の default branch を fetch し、作業 branch の merge-base、または detached HEAD が remote tip と一致することを確認する。
一致する専用 worktree にいる場合だけ、手順1と2を再実行しない。
それ以外は `git-usage` を使い、`git wt` を優先して worktree を作成する。

## 敵対的検証

サブエージェントには入力成果物、差分、テスト結果だけを渡す。
実装者の結論や期待する回答は渡さない。

設計との不一致、境界条件、回帰、テストの欠落、権限と機密情報のリスクを確認させる。
差分が変わったら再検証する。

## 人間レビュー

敵対的検証の指摘が 0 件になってから `difit-review` を使う。
実装意図、トレードオフ、確認してほしい箇所をコメントとして添える。

difit を閉じたときに返るコメントを確認し、ユーザーが追加したコメントへ対応する。
difit の process が終了するまで待ち、コメントを取得できない環境ではレビュー完了とコメント件数をユーザーが明示するまで停止する。
レビューが完了するまで commit、push、Draft PR 作成へ進まない。

## Draft PR

repository の PR template を優先する。
template がなければ [assets/pull_request_template.md](assets/pull_request_template.md) を使う。

## 振り返り

`.agent/` が Git の除外対象であり、追跡も stage もされていないことを確認する。
[assets/retrospective.md](assets/retrospective.md) を使い、Agent Rules、Agent Skills、権限設定の改善候補を残す。

認証情報、個人情報、未公開の機密情報は記録しない。
