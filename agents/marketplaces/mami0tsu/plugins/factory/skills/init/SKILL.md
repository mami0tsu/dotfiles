---
name: init
description: factory の設定を作成、修正、検証する。
compatibility: Requires CUE.
allowed-tools: >-
  Read
  Write
  AskUserQuestion
  Bash(cue export */skills/init/assets/config.cue *)
---

# Init

## 入力

| 項目 | 内容 |
| --- | --- |
| 設定パス | `factory.json` の絶対パス |
| 設定値 | [config.cue](assets/config.cue) に定義された値。Issue の保存先には GitHub リポジトリの URL を指定する |
| 不足項目 | 呼び出し元が必要とする設定値 |

## 出力

| 成果物 | 内容 |
| --- | --- |
| `factory.json` | 検証済みの factory 設定 |

## 手順

1. 設定パスを確定する。
   指定がない場合は作業ディレクトリの `factory.json` を使う。
1. 既存ファイルがあれば一時 JSON を作成し、`loop.skills` と `reviewers` の `plan`、`register` を削除する。
1. `loop.skills.inspect` がなく旧設定の `loop.skills.research` がある場合は、その `concurrency` と `intervalSeconds` を `loop.skills.inspect` に引き継ぐ。
   `maxOpenIssues` も inspect に移し、`additionalResearch.concurrency` は research の `concurrency` に移す。
   research の `intervalSeconds` は保持し、`additionalResearch` を削除する。
   `reviewers.research` が指定されている場合は、同じ値を `reviewers.inspect` にも設定する。
   `reviewers.inspect` が既に指定されている場合は、その値を保持する。
1. 一時 JSON を検証し、旧項目の削除や修正が不要で、不足項目も満たしていれば結果を返す。
1. CUE 定義と呼び出し元の不足項目を確認し、不足や不正な値、構造の修正に必要な情報を利用者に確認する。
   タスクを管理するサービス名、タスクの ID を構成するキー、着手可能な状態を示すサービス上の状態名を確認する。
   成果物の出力先は、調査対象リポジトリへのプルリクエスト、Wiki の記事、タスクへのコメントから選ぶ。
   プルリクエストではリポジトリ、Wiki ではサービス名を確認する。
   JSON を読み取れない場合も内容を確認し、修正内容を特定できなければ保留する。
1. 一時 JSON を用意して修正内容を反映し、既存の無関係な値を保持する。
1. 同じ出力先への初期化を直列に実行する。
   一時 JSON を検証し、不足項目も満たす場合に生成結果を設定パスに保存する。
   検証に失敗した場合や CUE が使えない場合は元のファイルを変更せず保留する。
1. [出力テンプレート](assets/result.md)で設定パスと結果、保留時の理由を返す。

```sh
cue export <skill-dir>/assets/config.cue json: /absolute/path/answers.json --out json --outfile /absolute/path/validated.json
cue export <skill-dir>/assets/config.cue json: /absolute/path/factory.json --out json
```

1 行目は一時 JSON の検証と生成、2 行目は設定ファイルの検証に使う。
`<skill-dir>` はこのスキルのディレクトリに置き換える。
