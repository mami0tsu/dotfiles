---
name: review
description: コードまたはテキスト文書のローカル変更を、通常検証、サブエージェントによる敵対的検証、関心別 commit、difit を使った人間レビューまで反復する。ユーザーがレビューを明示的に依頼した場合、または dev-flow からローカル差分の人間レビューを求められた場合に使う。GitHub PR とバイナリ文書のレビューには使わない。
---

# Review

変更前の commit を基点にし、人間の指摘がなくなるまで検証、commit、difit review を繰り返す。

## 実行環境

Codex では [Codex adapter](references/codex.md) を読む。

Claude Code では [Claude Code adapter](references/claude-code.md) を読む。

どちらにも該当しない場合、またはサブエージェントを利用できない場合は停止する。

## 状態を初期化する

変更を始める前の clean な worktree で次を実行する。

```sh
python3 <skill-dir>/scripts/review.py init
```

状態は `git rev-parse --git-path review-state.json` に保存される。

既存状態がある場合は上書きせず、再開するか破棄するかをユーザーへ確認する。

実装後に初めてレビューを依頼された場合、開始 commit を推測しない。

ユーザーから base SHA を受け取り、`init --base <sha>` を使う。

## 検証して commit する

次の順序を守る。

1. 変更を通常の方法で検証する。
2. 1つのサブエージェントへ要求、対象差分、関連コード、検証結果を渡す。
3. 設計との不一致、境界条件、回帰、テスト不足、権限と機密情報のリスクを検証させる。
4. 指摘を修正し、通常検証と同じサブエージェントによる再検証を繰り返す。
5. 指摘が 0 件になったら、`git-usage` を使って変更を関心別に commit する。

実装者の結論や期待する回答をサブエージェントへ渡さない。

差分が変わるたび、最新差分と検証結果を渡す。

検証が失敗している間は commit しない。

difit も起動しない。

## difit を起動する

worktree が untracked file を含めて clean であることを確認する。

説明コメントを JSON array として mode `600` の一時ファイルに用意する。

初回には設計意図、実装意図、実装説明を該当する変更行へ置く。

2 回目以降は、前回指摘への対応内容と修正意図を置く。

独立した判断は別の thread に分け、自明な変更へ説明を水増ししない。

difit の出力は同じ file と line にある複数 thread を識別できないため、同じ表示位置へ複数の thread を置かない。

```json
[
  {
    "type": "thread",
    "filePath": "path/to/file",
    "position": { "side": "new", "line": 10 },
    "body": "この行に対応する設計意図"
  }
]
```

比較範囲を取得する。

```sh
python3 <skill-dir>/scripts/review.py next
```

表示された `target`、`base`、`clean` を使って foreground で起動する。

```sh
python3 <skill-dir>/scripts/review.py run \
  --target <target> \
  --base <base> \
  --comments <comments-json> \
  [--clean]
```

helper は AI コメントへ次の marker を付け、raw transcript を mode `600` の一時ファイルへ保存する。

```text
<!-- difit-comment-author: agent -->
```

ブラウザが閉じて process が終了するまで待つ。

URL が表示されたあとも process を background 化しない。

## コメントへ対応する

`run` が表示した transcript path を使い、新規または編集された人間のメッセージを抽出する。

```sh
python3 <skill-dir>/scripts/review.py extract --transcript <path>
```

raw transcript と抽出結果を照合する。

marker のあるメッセージだけを AI の説明として除外する。

marker のない root comment と reply は人間のメッセージとして扱う。

`reviewed` で今回表示した target を人間レビュー済み checkpoint として記録する。

```sh
python3 <skill-dir>/scripts/review.py reviewed
```

対応を終えたメッセージの署名を記録する。

```sh
python3 <skill-dir>/scripts/review.py acknowledge <signature> [<signature>...]
```

照合後は transcript を削除する。

```sh
python3 <skill-dir>/scripts/review.py discard-transcript --transcript <path>
```

ファイル変更が必要な場合は、検証、関心別 commit、次の差分 review を行う。

質問への回答だけで変更が不要な場合は、同じ比較範囲を開き直す。

抽出結果の `filePath` と `replyPosition` がある場合だけ、該当位置へ `type: "reply"` の説明コメントを投入する。

`--clean` は付けない。

`replyPosition` がない場合や同じ表示位置に複数 thread がある場合は、返信先を推測せずに停止する。

既存の AI thread へ返信するようユーザーに依頼する。

新しい人間メッセージが 0 件になるまで繰り返す。

## 完了する

新しい人間メッセージが 0 件で、transcript を照合して削除した場合だけ完了する。

```sh
python3 <skill-dir>/scripts/review.py complete
```

helper が保持する review state は完了時だけ削除する。

## 停止条件

次の場合は state を保持して停止する。

- `difit` が見つからない。
- 必要な difit option を確認できない。
- worktree に未 commit または untracked の変更がある。
- checkpoint の commit または tree object が存在しない。
- 通常検証または敵対的検証が完了していない。
- difit process の終了結果からコメントを取得できない。
- difit の出力だけでは返信先を一意に特定できない。

`npx difit` へフォールバックしない。

履歴の書き換え後も、保存済み commit と tree object が存在する場合は両 tree の差分として続行する。
