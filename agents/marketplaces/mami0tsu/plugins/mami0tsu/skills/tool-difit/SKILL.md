---
name: tool-difit
description: >-
  difitを使い、local repositoryのcommit差分をブラウザへ表示して人間のレビューコメントを取得するためのTool。
  commit済みの変更をpushする前に、人間へ差分レビューを依頼するときに使う。
allowed-tools: >-
  Bash(command -v difit)
  Bash(difit * * --clean)
---

# tool-difit

## 制約

- 一つの操作ごとに、対応するreferenceを1つだけ読む。
- referenceにない操作を実行しない。
- `npx difit`へ切り替えない[^difit]。
- gitの状態とGitHub上の情報を変更しない。

## ユースケース

**実行環境の確認**

| ユースケース | 用途 |
| --- | --- |
| `inspect-installation` | difitの実行ファイルを確認する。 |

**commit差分のレビュー**

| ユースケース | 用途 |
| --- | --- |
| `review-commits` | base commitとtarget commitの差分を表示し、人間のコメントを取得する。 |

[^difit]: [difit README](https://github.com/yoshiko-pg/difit/blob/main/README.ja.md)
