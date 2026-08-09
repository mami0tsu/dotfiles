---
name: git-usage
description: Git で状態確認、worktree、branch、commit、fetch、pull、rebase、push を安全に実行するときに使うユースケース指向のリファレンス。
---

# Git Usage

この Skill は、状態確認、worktree、branch、commit、fetch、pull、rebase、push だけを扱う。

submodule、stash、cherry-pick、reset、branch 削除、worktree 削除、履歴の強制更新は対象外である。

すべての操作の前に、repository root、現在の branch、変更済み path を確認する。

```sh
git rev-parse --show-toplevel
git status --short --branch
```

remote と default branch は、名前を推測せず remote へ問い合わせて確認する。

```sh
git remote -v
git ls-remote --symref <remote> HEAD
```

`git ls-remote --symref <remote> HEAD` の `ref: refs/heads/<default-branch> HEAD` から default branch を取得する。

たとえば `ref: refs/heads/main HEAD` が出力された場合、remote は `<remote>`、default branch は `main` である。

`refs/remotes/<remote>/HEAD` は過去の fetch が残した stale な remote-tracking ref であり、remote default branch の情報源として使わない。

`git ls-remote --symref` が失敗した場合、または `HEAD` に対応する `refs/heads/` の symref を返さない場合は、branch 名を推測せず停止する。

確認コマンドと公式ドキュメントは、[remote と履歴を更新する](references/remote-integration.md) の情報源に記録する。

## 参照ファイル

- [状態確認と branch](references/state-and-branch.md)：状態確認と新しい branch を扱う。
- [worktree の一覧](references/worktree-list.md)：既存 worktree の path と branch を特定する。
- [worktree の作成](references/worktree-create.md)：新規または既存の branch に作業場所を作る。
- [変更を commit する](references/change-and-commit.md)：意図した path だけを stage して commit する。
- [remote と履歴を更新する](references/remote-integration.md)：fetch、pull、rebase、push を扱う。
- [検証記録](references/validation.md)：静的確認と Agent シナリオ試験の結果を記録する。

## 共通の安全規則

新しい作業は ticket ID を含む branch と専用 worktree に分ける。

既存の専用 worktree が目的を満たす場合は再利用する。

repository に命名規約がなければ、branch は `<type>/<ticket-id>/<short-description>` とする。

`type` は `feature`、`hotfix`、`chore` から変更内容に合うものを選ぶ。

ticket ID がない検証作業だけは `wip/<short-description>` を使う。

repository に commit message の規約がなければ、`<type>: <summary> <ticket-id>` を使う。

`git add -A`、`git commit -a`、無差別な pathspec は、変更の範囲を確認できないため使わない。

dirty な worktree を自動で stash しない。

force push、branch 削除、worktree 削除、`git reset --hard` は、利用者の明示的な依頼なしに実行しない。

状態を変更する前に、対象、主要コマンド、停止条件を利用者へ短く示す。

## ヘルプのフォールバック

Git 2.55.0 で検証済みの上記ユースケースでは、事前に `git --help` や `git <subcommand> --help` を読まず、この Skill のリファレンスに従う。

対象外の操作、記録と異なる Git version、未対応 option や構文エラーが発生した場合だけ、必要な subcommand のヘルプを読む。

たとえば rebase の構文を確認するなら `git rebase --help` だけを読む。

Git 全体のヘルプを念のために読むことはしない。

確認結果が記録済みの構文や挙動と異なる場合は、情報源、検証 version、確認コマンドを更新する。
