---
name: implement
description: 着手可能なタスクに沿ってコードを実装し、検証結果を返す。
compatibility: Requires Bash, Git, and git-wt.
allowed-tools: >-
  Read
  Write
  Edit
  Glob
  Grep
  Bash
  Skill
---

# Implement

## 入力

| 項目 | 内容 |
| --- | --- |
| `factory.json` | loop から渡された設定ファイルの絶対パス |

## 出力

| 成果物 | 内容 |
| --- | --- |
| 実装 | タスクに対応するコミット済みのコードの変更 |
| 検証結果 | 実行した確認とその結果 |
| PR の作成情報 | リポジトリの `OWNER/REPO`、worktree、リモート名、変更元と取り込み先のブランチ |

## 手順

### タスクの確認

1. 設定を確認する。
   設定が存在しない、不正または不足している場合は、設定パスと不足項目を loop に返して終了する。
1. タスク管理サービスに対応するスキルで、自分に割り当てられた着手可能なタスクを取得する。
   着手可能な状態は `states.tasks.ready` を使う。
1. 各タスクの作業範囲、受け入れ条件と出力先を確認する。
   出力先が `pull-request` のタスクを対象とし、不足や矛盾がある場合は保留する。

### 実装

1. 対象リポジトリと既存の成果物を確認する。
   同じタスクに対応する成果物がある場合は再利用する。
1. git-wt でタスクごとに専用の worktree とブランチを用意する。
   worktree 名は `<task-id>-<short-description>` とする。
   リポジトリにブランチの命名規約がなければ、`<type>/<task-id>/<short-description>` とする。
   `type` は `feature`、`hotfix`、`chore` から選ぶ。
1. [prepare-worktree.sh](scripts/prepare-worktree.sh) に対象リポジトリの絶対パス、リモート名、ブランチ名と worktree 名を渡して実行する。
   デフォルトブランチを最新化し、新しいブランチはそのコミットを起点にする。
   返されたパスを作業場所とし、準備できない場合は保留する。
1. タスクの受け入れ条件に沿って実装し、必要なテストなどで検証する。
   可読性とメンテナンス性を保ち、必要な拡張やテストのしやすさも考慮して、シンプルで簡潔な実装を選ぶ。
1. コードコメントは必要な場合に記載し、日本語のコメントを japanese-tech-writing、cognitive-rhythm-writing、yomiyasu の各スキルで推敲する。
   トレードオフを踏まえて手法を選んだ場合は、その理由をコメントに記載する。
   コメント本文は1行に一文を書き、文末に句点を付ける。
   プレフィックス付きのコメントが複数行になる場合は、2行目以降を1行目の本文の開始位置に揃える。
   `refs:` 行は参照元のコメント本文の開始位置に揃え、後ろには句点を付けず URL だけを記載する。
   次のプレフィックスは必要な場合に使う。

   | プレフィックス | 用途 |
   | --- | --- |
   | `TODO:` | 後で行う作業 |
   | `FIXME:` | 修正が必要な不具合 |
   | `NOTE:` | 実装上の補足や見落としやすい前提 |
   | `WARN:` | 変更や利用の際に注意が必要な事項 |
   | `refs:` | 根拠や参考となる情報の URL |

1. 検証した変更を関心ごとにコミットする。
   コミットメッセージはリポジトリの規約を確認し、[Conventional Commits 1.0.0](https://github.com/conventional-commits/conventionalcommits.org/blob/master/content/v1.0.0/index.ja.md) に従う。
   タイトルにはタスク ID を含める。
1. [commit.sh](scripts/commit.sh) に worktree の絶対パス、コミットメッセージと worktree からの対象ファイルの相対パスを渡して実行する。
1. タスク、PR の作成情報と検証結果を loop に返す。
