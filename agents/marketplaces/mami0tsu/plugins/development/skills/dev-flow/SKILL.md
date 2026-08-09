---
name: dev-flow
description: レビュー済みのチケットや設計成果物を実装し、worktree、検証、関心別 commit、difit による人間レビュー、Draft PR、振り返りまで完了させる開発フロー。チケットに沿って開発するときに使う。
---

# Development Flow

レビュー済みのチケットまたは設計成果物を入力にする。
入力が不足している場合は実装せず、`documentation` plugin で更新してレビューを受ける。

## 手順

1. default branch を更新する。
2. 専用 worktree と ticket ID を含む branch を用意する。
3. 変更前の HEAD で `review` の状態を初期化する。
4. 入力成果物の範囲内で実装し、テストする。
5. `review` で検証、関心別 commit、人間レビューを完了する。
6. 変更を push し、`gh-usage` で Draft PR を作成する。
7. `retrospective` で振り返りを記録する。

worktree を再利用する前に remote の default branch を fetch する。
作業 branch の merge-base、または detached HEAD が remote tip と一致することを確認する。
一致する専用 worktree にいる場合だけ、手順1と2を再実行しない。
それ以外は `git-usage` を使い、`git wt` を優先して worktree を作成する。

## 人間レビュー

`review` に通常検証、サブエージェントによる敵対的検証、関心別 commit、difit の終了待機、コメント対応を委譲する。

人間のコメントが 0 件になるまで push と Draft PR 作成へ進まない。

## Draft PR

repository の PR template を優先する。
template がなければ [assets/pull_request_template.md](assets/pull_request_template.md) を使う。

## 振り返り

`.agent/` が Git の除外対象であり、追跡も stage もされていないことを確認する。
`retrospective` に ticket ID、作業履歴、実行許可を求めたコマンドを渡す。
