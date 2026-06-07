---
name: managing-development-tasks
description: タスク概要、issue 詳細、チケット文脈から開発タスクを開始または完了するときに使う。タスク用 Git branch と worktree を git wt で作成し、ブランチ命名規則、コミットメッセージ作成、push、draft PR 作成を扱う。外部タスク管理システムからチケット情報は取得しない。
---

# Managing Development Tasks

ユーザーまたは別の Skill からタスク情報が渡された後に、この Skill を使う。ブランチ命名、worktree 作成、コミットメッセージ、push、draft PR 作成までの開発作業フローを標準化する。

外部のタスク管理システムからタスク情報を取得しない。チケット状態を更新しない。渡されたタスク情報以外の、ツール固有フィールドを前提にしない。

## Input

会話内で利用可能なタスク情報を入力として扱う:

- タスク概要
- チケット番号または識別子
- 目的
- 想定される変更範囲
- 制約またはメモ

必要な入力が不足している場合は、渡されたタスク文脈から保守的に推測する。ブランチ命名、worktree 配置、PR 内容にリスクのある曖昧さが残る場合だけ、ユーザーに確認する。

## Branch Naming

次の形式を使う:

```text
<type>/<ticket-id>/<short-description>
```

利用可能な `type`:

```text
feature
hotfix
chore
```

ガイドライン:

- タスク識別子は追跡できる粒度で含める。
- 短い説明は lowercase、簡潔、hyphen-separated にする。
- 新機能は `feature`、不具合修正は `hotfix`、ツールや保守作業は `chore` を優先する。
- ブランチ作成前に、同名ブランチが存在しないか確認する。

## Deterministic Git Context

Git 操作に必要な情報は、推測ではなくコマンドで取得する。

リポジトリルート:

```bash
git rev-parse --show-toplevel
```

現在のブランチ:

```bash
git branch --show-current
```

remote の既定 base branch:

```bash
git symbolic-ref --short refs/remotes/origin/HEAD
```

上記が失敗する場合は、`origin/main` を第一候補として確認する:

```bash
git rev-parse --verify origin/main
```

ローカルブランチの存在確認:

```bash
git show-ref --verify --quiet refs/heads/<branch-name>
```

remote ブランチの存在確認:

```bash
git show-ref --verify --quiet refs/remotes/origin/<branch-name>
```

既存 worktree の確認:

```bash
git wt --json
```

`git wt` の設定確認:

```bash
git config --get wt.basedir
git config --get wt.nocd
```

## Worktree Creation

`main` で直接作業しない。

worktree の作成、切り替え、削除には Git サブコマンドとして `git wt` を使う。`git worktree` を直接実行しない。

ワークフロー:

1. `git rev-parse --show-toplevel` でリポジトリルートを取得する。
2. `git status --short` で作業ツリー状態を確認する。
3. `git symbolic-ref --short refs/remotes/origin/HEAD` で base branch を取得する。
4. `git wt --json` で既存 worktree を確認する。
5. local branch、remote branch、worktree 名が衝突しないことを確認する。
6. `git wt --nocd -b <branch-name> <worktree-name> <base-ref>` で branch と worktree を同時に作成する。

推奨 worktree base dir:

```text
../<repo-name>-worktrees
```

`wt.basedir = "../{gitroot}-worktrees"` を前提にする。`git wt` は relative basedir を現在の subdirectory ではなく repository root 基準で解決し、`{gitroot}` は repository root のディレクトリ名に展開する。

worktree 名:

```text
<ticket-id>-<short-description>
```

worktree 名には branch name 全体を使わず、slash を含まない `<ticket-id>-<short-description>` を使う。

例:

```bash
git wt --nocd -b feature/ABC-123/add-elapsed-time ABC-123-add-elapsed-time origin/main
```

リポジトリに既存の worktree 規約がある場合は、それを優先する。

## Commit Messages

Conventional Commits の `type` は維持し、summary は日本語で書く:

```text
<type>: <summary>
```

例:

```text
feat: 経過時間の共有機能を追加
hotfix: 通知の重複送信を防止
chore: 依存パッケージを更新
```

summary は簡潔にし、ユーザーに見える結果または保守上の結果に焦点を当てる。

## Push

タスク用ブランチを既定 remote、通常は `origin` に push する:

```bash
git push -u origin <branch-name>
```

ユーザーの明示的な確認なしに force push しない。

## Draft Pull Request

draft PR は次のコマンドで作成する:

```bash
gh pr create --draft
```

PR body は次の構造を使う:

```markdown
## 概要

## 変更内容

## レビュー観点

## 参考情報
```

## Safety Rules

危険な Git 操作を実行する前に、ユーザーの明示的な確認を要求する:

- force push
- branch delete
- `git wt -d` または `git wt -D` による worktree delete
- `reset --hard`

ブランチ名や worktree 名を空けるためだけに破壊的な cleanup を行わない。衝突しない名前を選ぶか、ユーザーに確認する。
