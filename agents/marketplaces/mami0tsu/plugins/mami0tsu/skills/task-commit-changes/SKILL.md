---
name: task-commit-changes
description: >-
  確認済みの変更から意図したファイルだけを選び、関心ごとのcommitを作るTask。
  test、lint、buildの結果を確認した後に変更を記録するときに使う。
allowed-tools: >-
  Skill
---

# task-commit-changes

変更結果と確認結果を照合し、説明できる単位でcommitを作る。
意図しないファイルや確認に失敗した変更はcommitしない。

## 入力

- 変更結果
- 確認結果
- 直前のcommit済みの変更（再実行時）

## 出力

- commit済みの変更

## 制約

- 必要な確認が失敗または未実行の場合はcommitを作らない。
- 各commitには、その関心に属する変更だけを含める。
- secret、生成物、作業開始前から存在する変更をcommitに含めない。
- 既存commitを整理しない。

## 手順

### 1. 変更と確認結果を照合する

変更済みファイルが変更結果に含まれていることを確認する。
必要な確認が成功していることを確認する。
Issueに基づく作業では、変更結果にIssue IDが含まれていることを確認する。

### 2. Commitの単位を決める

変更を独立して説明できる関心ごとに分け、各commitに含めるファイルとmessageを決める。
各関心には異なるmessageを付ける。
新しく作る関心別commitのmessageの1行目は`<type>[optional scope][!]: <description>`の形式にする[^conventional-commits]。
Issueに基づく作業では、1行目を`<type>[optional scope][!]: <description-ja> <issue-id>`の形式にする。
変更の主目的に応じてtypeを選ぶ。

| type | 用途 |
| --- | --- |
| `build` | build処理または依存関係だけを変更する。 |
| `chore` | 他のtypeに該当しない保守作業を行う。 |
| `ci` | CIの設定またはworkflowだけを変更する。 |
| `docs` | 文書だけを変更する。 |
| `feat` | 機能を追加する。 |
| `fix` | 不具合を修正する。 |
| `perf` | 動作を変えずに性能を改善する。 |
| `refactor` | 機能や不具合を変えずにコード構造を変更する。 |
| `revert` | 以前のcommitを取り消す。 |
| `style` | 動作に影響しない書式だけを変更する。 |
| `test` | testだけを追加または変更する。 |

typeとscopeは英小文字で書く。
description、body、footerの説明文は日本語で書く。
固有名詞、path、識別子、footerのtokenは元の表記を保つ。
Issue IDは仕様の読み取り結果にある表記を変えず、descriptionの末尾へ付ける。
破壊的変更はtypeまたはscopeの直後へ`!`を付けるか、`BREAKING CHANGE:` footerで示す。
bodyやfooterを付ける場合は、直前へ空行を入れる。
直前のcommit済みの変更がある場合は、各変更がどのcommitの関心に属するか確認する。

### 3. Commitを作る

新しい関心の変更は、新しいcommitとして記録する。
既存commitと同じ関心の修正は、後でそのcommitへまとめられる形で記録する。
各commitに含めるファイルを明示して、1つずつcommitを作る。
各commitを作る前に、そのcommitへ含める差分を確認する。

### 4. Commit済みの変更を返す

これまでに作成したcommitのhash、message、関心、含まれるファイル、修正をまとめる先、最後に作成した対象commit、確認結果をcommit済みの変更として返す。

[^conventional-commits]: [Conventional Commits 1.0.0](https://www.conventionalcommits.org/ja/v1.0.0/)
