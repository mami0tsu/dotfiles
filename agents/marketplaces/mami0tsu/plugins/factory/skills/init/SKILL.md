---
name: init
description: >-
  factory の設定を初期化する。
  利用者が初期設定を依頼したとき、または loop が設定の不存在を確認したときに使う。
  既存の設定は検証し、無断で上書きしない。
compatibility: Requires CUE.
allowed-tools: >-
  Read
  Write
  AskUserQuestion
  Bash(cue export */skills/init/assets/config.cue *)
---

# Init

1. 出力先の `factory.json` の絶対パスを確定する。
   loop からは設定パスを受け取り、別の場所を推測しない。
2. 既存ファイルがあれば次の検証コマンドを実行し、不正なら停止する。
   不正なファイルを未作成として扱わない。
   有効な既存設定は再生成せず、その検証結果を返す。
3. 新規作成では [config.cue](assets/config.cue) のコメントから必要値を確認し、利用者の回答を一時 JSON に記録する。
   アイデアとタスクの管理先、名前付きの出力先をそれぞれ確認する。
   CUE の編集は求めない。
   自動実行で必須値が不明なら推測せず、不足項目を返して保留する。
4. 未作成の場合だけ次の生成コマンドを実行する。
   `--force` や出力リダイレクトは使わず、失敗したら停止する。
   同じ出力先への初期化は直列に実行する。
5. [出力テンプレート](assets/result.md)でパスと結果、保留時の不足項目を報告する。

```sh
cue export <skill-dir>/assets/config.cue json: /absolute/path/answers.json --out json --outfile /absolute/path/factory.json
cue export <skill-dir>/assets/config.cue json: /absolute/path/factory.json --out json
```

`<skill-dir>` はこのスキルのディレクトリに置き換える。
各処理スキルは開始時に同じ検証コマンドを実行し、成功時に標準出力へ返る既定値補完済み JSON を使う。
検証は既存ファイルを書き換えない。
CUE が使えない場合は自動インストールせず保留する。
