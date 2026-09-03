---
name: tool-git
description: >-
  `git`と`git wt`を使い、GitHub repositoryのlocal worktree、branch、commit、remoteとの同期を扱うためのTool。
  worktree、branch、commit、remoteを確認または変更するときに使う。
allowed-tools: >-
  Bash(${CLAUDE_SKILL_DIR}/scripts/inspect-worktree.sh *)
  Bash(git -C * add -- *)
  Bash(git -C * apply)
  Bash(git -C * branch -d *)
  Bash(git -C * clean -fd -- *)
  Bash(git -C * commit --fixup=*)
  Bash(git -C * commit -m *)
  Bash(git -C * fetch *)
  Bash(git -C * pull --ff-only *)
  Bash(git -C * push --dry-run --porcelain *)
  Bash(git -C * push --porcelain --set-upstream *)
  Bash(git -C * rebase */*)
  Bash(git -C * rebase --abort)
  Bash(git -C * restore --staged -- *)
  Bash(git -C * restore --worktree -- *)
  Bash(git -C * switch *)
  Bash(git -C * wt --json --nocd)
  Bash(git -C * wt --json)
  Bash(git -C * wt --nocd *)
  Bash(GIT_SEQUENCE_EDITOR=: git -C * rebase --interactive --autosquash *)
---

# tool-git

## 制約

- 1つの操作ごとに、対応するreferenceを1つだけ読む。
- referenceにない操作はしない。
- worktreeの操作には`git wt`を使い、`git worktree`へ切り替えない[^git-wt]。
- dirtyなworktreeを自動でstashしない。
- submodule、stash、cherry-pick、reset、mergeは扱わない。

## ユースケース

**状態の確認**

| ユースケース | 用途 |
| --- | --- |
| `compare-commits` | base commitとtarget commitの差分を取得する。 |
| `inspect-changes` | 未stage、stage済み、untrackedの変更を取得する。 |
| `inspect-push` | pushによるremote branchの変更をdry-runで確認する。 |
| `inspect-remote-branch` | remote branchが存在するか確認する。 |
| `inspect-remotes` | 設定済みのremoteとURLを取得する。 |
| `inspect-worktree` | repository root、branch、HEAD、statusを取得する。 |

**branchの操作**

| ユースケース | 用途 |
| --- | --- |
| `autosquash-commits` | 未公開のfixup commitを関心ごとのcommitへまとめる。 |
| `create-branch` | 指定した起点からbranchを作る。 |
| `fast-forward-branch` | branchをremote branchへfast-forwardする。 |
| `fetch-remote` | remoteのdefault branchを確認してfetchする。 |
| `push-branch` | branchをremoteへpushする。 |
| `rebase-branch` | 作業branchをremote branchへrebaseする。 |

**worktreeの操作**

| ユースケース | 用途 |
| --- | --- |
| `attach-worktree` | 既存branchへ新しいworktreeを関連付ける。 |
| `create-worktree` | 新しいbranchとworktreeを作る。 |
| `list-worktrees` | 登録済みworktreeを取得する。 |
| `migrate-worktree` | primary worktreeの未commit変更を専用worktreeへ移す。 |
| `switch-worktree` | 既存worktreeのpathを取得する。 |

**変更の記録**

| ユースケース | 用途 |
| --- | --- |
| `commit-changes` | 指定されたpathを1つのcommitへ記録する。 |
| `commit-fixup` | 指定されたpathを既存commitのfixup commitへ記録する。 |
| `unstage-changes` | 指定したpathをunstageする。 |

[^git-wt]: [k1LoW/git-wt](https://github.com/k1LoW/git-wt)
