---
name: pre-push-review
description: push 前の commit 済みコードまたはテキスト差分を、通常検証、専門 sub-agent による敵対的検証、difit の人間レビューへ通す。clean な worktree と明示された base、target commit を受け取るときに使う。GitHub PR とバイナリ文書のレビューには使わない。
---

# Pre-push Review

明示された base と target の commit 済み差分を、push 前に検証する。

この Skill はファイルを修正せず、commit も作成しない。

修正が必要な場合は findings を呼び出し元へ返し、新しい commit を受け取って再開する。

## 実行環境

Codex では [Codex adapter](references/codex.md) を読む。

Claude Code では [Claude Code adapter](references/claude-code.md) を読む。

どちらにも該当しない場合、または sub-agent を利用できない場合は停止する。

## 入力を検証する

base と target は完全な commit OID で受け取る。

両方が commit object として存在し、target が現在の HEAD と一致し、base と target が異なることを確認する。

worktree は staged、unstaged、untracked file を含めて clean でなければならない。

次のコマンドで状態を初期化する。

```sh
python3 <skill-dir>/scripts/pre_push_review.py init \
  --base <base-commit> \
  --target <target-commit>
```

状態は `git rev-parse --git-path pre-push-review-state.json` に保存される。

既存状態がある場合は上書きせず、初期化時の base と target を再度渡し、保存済み identity と一致する場合だけ再開する。

初回レビュー後に新しい commit がある場合も、初期化時の identity を渡す。

base または target を branch 名、tag、暗黙の HEAD から推測しない。

## 通常検証と敵対的検証を行う

最初に、対象変更へ通常必要な test、lint、build、文書検査を実行する。

通常リスクでは、1つの専門 sub-agent を選ぶ。

認証、権限、永続化、並行処理、外部公開、複数 component へまたがる変更では、互いに異なる観点の2つまたは3つの専門 sub-agent を選ぶ。

各 sub-agent には要求、base と target、対象差分、関連コード、通常検証結果を渡す。

実装者の結論や期待する回答は渡さない。

設計との不一致、境界条件、回帰、test 不足、権限と機密情報のリスクを独立に検証させる。

全 sub-agent の findings を重複排除し、誤検知と根拠不足を除外する。

通常検証と必要数の sub-agent 検証が成功した target だけを記録する。

```sh
python3 <skill-dir>/scripts/pre_push_review.py validated \
  --base <base-commit> \
  --target <target-commit> \
  --risk <normal-or-high> \
  --normal-check <check-label> [--normal-check <check-label>...] \
  --subagent <agent-id> [--subagent <agent-id>...]
```

通常リスクは1つ、高リスクは2つまたは3つの異なる sub-agent ID を必須とする。

検証記録は base tree と target tree の比較範囲へ結び付ける。

検証内容そのものではなく、再実行可能な check label と sub-agent ID だけを state に保存する。

通常検証が失敗した場合、必要数の sub-agent を利用できない場合、actionable finding が残る場合は difit を起動しない。

修正が必要なら、finding、根拠、再検証条件を呼び出し元へ返す。

呼び出し元が修正を commit した後、同じ sub-agent に新しい target と検証結果を渡して再検証する。

## difit を起動する

通常検証と敵対的検証が完了し、worktree が clean であることを再確認する。

説明コメントを JSON array として mode `600` の一時ファイルに用意する。

初回には設計意図、実装意図、実装説明を該当する変更行へ置く。

2回目以降は、前回指摘への対応内容と修正意図を置く。

同じ表示位置へ複数 thread を置かない。

```json
[
  {
    "type": "thread",
    "filePath": "path/to/file",
    "position": {"side": "new", "line": 10},
    "body": "この行に対応する設計意図"
  }
]
```

比較範囲を取得する。

```sh
python3 <skill-dir>/scripts/pre_push_review.py next
```

表示された `targetCommit` と `baseCommit` を検証記録に使う。

`target`、`base`、`clean` はそのまま difit の起動に使う。

```sh
python3 <skill-dir>/scripts/pre_push_review.py run \
  --target <target> \
  --base <base> \
  --comments <comments-json> \
  [--clean]
```

helper は Agent comment の識別情報と raw transcript を private file に保存する。

helper は difit を `--keep-alive` で起動し、browser disconnect を検出したあと SIGINT でコメント出力を取得する。

ブラウザが閉じて process が終了するまで待つ。

URL が表示されたあとも process を background 化しない。

difit が異常終了または中断した場合、表示された transcript を人間が確認する。

再実行する場合は、確認後に未完了 transcript を明示的に破棄する。

helper は difit の process group が終了している場合だけ破棄する。

```sh
python3 <skill-dir>/scripts/pre_push_review.py discard-transcript \
  --transcript <path> \
  --allow-incomplete
```

## 人間コメントを処理する

`run` が表示した transcript path から新規または編集された人間のメッセージを抽出する。

```sh
python3 <skill-dir>/scripts/pre_push_review.py extract --transcript <path>
```

raw transcript と抽出結果を照合し、ファイル変更前に今回の target を review 済みとして記録する。

```sh
python3 <skill-dir>/scripts/pre_push_review.py reviewed
```

今回抽出したメッセージの署名をすべて記録し、transcript を削除する。

抽出していない署名は記録せず、未記録の署名が残る transcript は削除しない。

```sh
python3 <skill-dir>/scripts/pre_push_review.py acknowledge <signature> [<signature>...]
python3 <skill-dir>/scripts/pre_push_review.py discard-transcript --transcript <path>
```

修正が必要な場合は、この Skill 内で変更せず findings を呼び出し元へ返す。

呼び出し元から新しい commit 済み target を受け取ったら、通常検証と同じ sub-agent による再検証から繰り返す。

質問への回答だけで変更が不要な場合は、同じ比較範囲を開き直す。

返信先を一意に特定できない場合は推測せず停止する。

新しい人間メッセージが0件になるまで繰り返す。

## 完了する

新しい人間メッセージが0件で、transcript を照合して削除した場合だけ完了する。

```sh
python3 <skill-dir>/scripts/pre_push_review.py complete
```

helper が保持する state は完了時だけ削除する。

完了時に base、最終 target、通常検証、sub-agent の選定理由と結果、人間レビュー結果を呼び出し元へ返す。

push は呼び出し元が実行する。

## 停止条件

次の場合は state を保持して停止する。

- base または target が明示されていない。
- target と HEAD が一致しない。
- worktree に未 commit または untracked の変更がある。
- 通常検証が完了していない。
- 必要数の sub-agent が利用できない、または検証が完了していない。
- actionable finding が残っている。
- `difit` が見つからない、または必要な option がない。
- checkpoint の commit または tree object が存在しない。
- difit process の終了結果からコメントを取得できない。
- 返信先を一意に特定できない。

`npx difit`へフォールバックしない。

終了制御とコメント出力形式を検証済みの difit 4.0.5 だけを使う。

履歴の書き換え後も保存済み commit と tree object が存在する場合は、両 tree の差分として続行できる。
