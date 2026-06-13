# promote-wip-branch

`wip/` branch を ticket-id 付き branch に昇格する。

Draft PR の close や remote `wip/` branch の削除はこの skill では実行しない。GitHub 側の操作は別 skill に任せる。

## 前提

- 現在 branch は `wip/<short-description>`
- ticket-id を取得できる
- 新しい branch 名は `<type>/<ticket-id>/<short-description>`
- 分岐後の全 commit message を `<type>: <summary> <ticket-id>` 形式に揃える
- 既存 remote `wip/` branch へ force push しない
- 新しい ticket-id 付き branch として push する

## 手順

1. `common/context.md`、`common/safety.md`、`common/naming.md`、`common/execution-plan.md` を読む。
2. 現在 branch が `wip/` でなければ止める。
3. dirty なら止める。
4. ticket-id と新 branch 名を決める。
5. `git fetch origin` を実行し、remote default branch を解決する。
6. `git merge-base HEAD <remote-default-branch>` を取得する。
7. merge-base 以降の commit 一覧と現在 message を表示する。
8. Conventional Commits 形式でない message があれば中断し、ユーザーに修正方針を確認する。
9. ticket-id が末尾にない commit message へ ticket-id を付ける変更後 preview を表示する。
10. 実行計画を表示する。
11. interactive rebase を非対話で実行し、対象 commit を reword する。
12. local branch を ticket-id 付き branch 名へ rename する。
13. 新しい branch を push する。

## 対象 commit

対象は remote default branch から分岐後の全 commit。

```sh
git fetch origin
base_ref=$(git symbolic-ref --short refs/remotes/origin/HEAD)
merge_base=$(git merge-base HEAD "$base_ref")
git log --reverse --format="%H%x09%s" "$merge_base"..HEAD
```

## rewrite 方針

Conventional Commits 形式の message だけ自動付与する。

```text
<type>: <summary>
<type>: <summary> <ticket-id>
```

形式外の message がある場合は promote を中断する。

## branch rename と push

```sh
git branch -m <new-branch-name>
git push -u origin <new-branch-name>
```

remote `wip/` branch の削除は行わない。
