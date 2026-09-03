# inspect-worktree

指定したworktreeのrepository root、branch、HEAD、statusを取得する[^git-rev-parse]。

## 入力

- worktreeのpath

## 出力

- repository root
- branch
- HEAD
- status

## 制約

- repositoryのstateを変更しない。
- worktreeのpathを省略しない。

## 手順

### 1. Worktreeを確認する

```sh
scripts/inspect-worktree.sh <worktree-path>
```

### 2. 結果を返す

scriptが出力したrepository root、branch、HEAD、statusを返す。

[^git-rev-parse]: [Git `rev-parse` manual](https://git-scm.com/docs/git-rev-parse)、[Git `status` manual](https://git-scm.com/docs/git-status)
