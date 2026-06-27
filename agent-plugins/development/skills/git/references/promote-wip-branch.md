# promote-wip-branch

`wip/` branch を ticket-id 付き branch に昇格する。

## 前提

- [rule-safety.md](rule-safety.md) と [rule-naming.md](rule-naming.md) を読む
- 現在 branch は `wip/<short-description>`
- ticket-id を取得できる
- 新しい branch 名は `<type>/<ticket-id>/<short-description>`
- 分岐後の全 commit message を `<type>: <summary> <ticket-id>` 形式に揃える
- 既存 remote `wip/` branch へ force push しない
- 新しい ticket-id 付き branch として push する

## 確認コマンド

現在 branch と dirty 状態:

```sh
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
```

現在 branch が `wip/` でない、または dirty なら止める。

対象 commit:

```sh
git fetch origin
git rev-parse --verify origin/main
git merge-base HEAD origin/main
git log --reverse --format="%H%x09%s" <merge-base>..HEAD
```

merge-base 以降の commit 一覧と現在 message を表示する。

## rewrite 方針

Conventional Commits 形式の message だけ自動付与する。

```text
<type>: <summary>
<type>: <summary> <ticket-id>
```

形式外の message がある場合は promote を中断する。

ticket-id が末尾にない commit message へ ticket-id を付ける変更後 preview を表示する。

## 実行前に表示する項目

- repository root
- current branch
- new branch name
- remote base branch: `origin/main`
- merge-base
- rewrite 対象 commit と変更後 message
- push 先 remote
- 実行する主要コマンド
- 停止条件

## 実行コマンド

commit message rewrite は interactive rebase を非対話で実行し、対象 commit を reword する。
既存 remote `wip/` branch へ force push しない。

```sh
git branch -m <new-branch-name>
git push -u origin <new-branch-name>
```

remote `wip/` branch の削除は行わない。
