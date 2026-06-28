---
name: development-flow
description: >-
  設計、チケット化、実装、レビューまでの開発フローを守るために使う。
  設計時は dig skill で深掘りして設計ドキュメントやチケットを作成し、開発時はレビュー済みの設計成果物を入力にして dig skill を省く。
  設計成果物作成後と実装後は difit-review skill による人間レビューを必須にする。
---

# Development Flow

設計から実装までの上位フローを定義する。
Git 操作や GitHub 操作は直接ここに再定義せず、必要に応じて `git` skill と `github-operation` skill を呼び出す。

## 前提 skill

この skill は次の外部 skill が利用できる環境を前提にする。

- `dig` skill: 設計、プラン、技術的意思決定を深掘りする
- `difit-review` skill: 実装意図、トレードオフ、迷った点、確認してほしい観点をコメントとして差分に添えて人間レビューに出す

前提 skill が使えない場合は、フローを継続しない。
不足している skill 名をユーザーに伝え、環境を整えてから再開する。

## 使う場面

次の依頼ではこの skill を使う:

- 実装前に設計や方針を固める
- 設計ドキュメント、チケット、実装ブリーフを作る
- 既存の設計成果物を入力にして実装する
- 「設計済みなので実装して」「このチケットに沿って開発して」のように、設計成果物から開発を始める
- 実装後にレビュー必須の開発フローを通す

## フロー選択

ユーザーの依頼に合わせて、どちらか一方を読む。

- 設計、方針決め、チケット化、実装ブリーフ作成: [references/design.md](references/design.md)
- レビュー済み設計成果物を入力にした実装: [references/implementation.md](references/implementation.md)

依頼が設計と実装の両方を含む場合は、先に設計フローを完了する。
設計成果物が `difit-review` skill でレビューされてから実装フローへ進む。

## 成果物テンプレート

成果物は `assets/` のテンプレートから選ぶ。

- 汎用設計ドキュメント: [assets/design-doc.md](assets/design-doc.md)
- クラウドインフラ設計ドキュメント: [assets/design-doc-sre.md](assets/design-doc-sre.md)
- アプリケーション設計ドキュメント: [assets/design-doc-app.md](assets/design-doc-app.md)
- チケット: [assets/ticket.md](assets/ticket.md)
- 実装ブリーフ: [assets/implementation-brief.md](assets/implementation-brief.md)

テンプレートは成果物種別で選ぶ。
変更規模や目的の違いはテンプレート内のセクションで表現する。

## レビューゲート

この skill では `difit-review` skill による人間レビューを必須にする。

- 設計成果物を作成または更新した直後に `difit-review` skill を使う
- 実装を完了した直後に `difit-review` skill を使う
- `difit-review` では、実装意図、トレードオフ、迷った点、確認してほしい観点を差分コメントとして添える
- レビューコメントが返った場合は対応し、必要なら再度 `difit-review` skill を使う
- ブラウザで開いた `difit` をユーザーが閉じるまで待つ
- レビューコメントが 0 件で返るまでレビューを繰り返す
- レビュー前に commit、push、Draft PR 作成へ進まない

## 下位 skill との関係

- branch、worktree、commit、rebase、push は `git` skill を使う
- Issue、Discussion、PR、CI、review comment の確認や Draft PR 作成は `github-operation` skill を使う
- この skill は開発判断とゲートを管理する。低レベル手順は下位 skill に委譲する
