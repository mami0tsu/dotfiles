---
name: tool-gh
description: >-
  GitHub CLIを使い、GitHub上のrepository、Issue、pull request、Actions、review commentを読み取り、Issue、Draft PR、pending review、stacked PRを扱うためのTool。
  GitHub上の情報を確認し、対応する操作を行うときに使う。
allowed-tools: >-
  Bash(bash */skills/tool-gh/scripts/private-body-file.sh create)
  Bash(bash */skills/tool-gh/scripts/private-body-file.sh remove --file *)
  Bash(gh api graphql --paginate *)
  Bash(gh api graphql -F owner=* -F name=* -F number=* -f query=*)
  Bash(gh api graphql -F pullRequestId=* -F commitOID=* -f query=*)
  Bash(gh api graphql -F reviewId=* -F body=@* -f query=*)
  Bash(gh api graphql -F reviewId=* -F path=* -F line=* -F side=* -F body=@* -f query=*)
  Bash(gh api graphql -F reviewId=* -F threadId=* -F body=@* -f query=*)
  Bash(gh auth status --hostname *)
  Bash(gh issue close * --repo * --reason completed)
  Bash(gh issue create --repo * --title * --body-file *)
  Bash(gh issue edit * --repo * --add-assignee *)
  Bash(gh issue edit * --repo * --add-blocked-by *)
  Bash(gh issue edit * --repo * --add-label *)
  Bash(gh issue edit * --repo * --title * --body-file *)
  Bash(gh issue edit * --repo * --parent *)
  Bash(gh issue edit * --repo * --remove-assignee *)
  Bash(gh issue edit * --repo * --remove-blocked-by *)
  Bash(gh issue edit * --repo * --remove-label *)
  Bash(gh issue edit * --repo * --remove-parent)
  Bash(gh issue list --repo * --state all --limit * --search * --json number,state,title,url,createdAt,updatedAt)
  Bash(gh issue reopen * --repo *)
  Bash(gh issue view * --repo * --json number,id,state,stateReason,title,body,assignees,labels,parent,subIssues,blockedBy,blocking,url,updatedAt)
  Bash(gh pr checks * --repo * --json name,state,bucket,workflow,link)
  Bash(gh pr create --repo * --draft --base * --head * --title * --body-file *)
  Bash(gh pr list --repo * --head * --state all --json number,state,isDraft,baseRefName,headRefName,title,url)
  Bash(gh pr view * --repo * --json number,isDraft,baseRefName,headRefName,title,body,url)
  Bash(gh pr view * --repo * --json number,state,isDraft,author,baseRefName,headRefName,headRefOid,commits,title,body,reviewDecision,mergeStateStatus,mergeCommit,mergedAt,changedFiles,additions,deletions,files,statusCheckRollup,url)
  Bash(gh pr view * --repo * --json number,url,reviews,comments)
  Bash(gh repo view * --json nameWithOwner,url,defaultBranchRef)
  Bash(gh run list --repo * --branch * --limit * --json databaseId,workflowName,status,conclusion,headSha,createdAt,url)
  Bash(gh run view * --repo * --json databaseId,workflowName,status,conclusion,jobs,url)
  Bash(gh run view * --repo * --log-failed)
  Bash(gh run view --repo * --job * --log-failed)
  Bash(gh stack link --remote *)
  Skill(mami0tsu:tool-git)
---

# tool-gh

## 制約

- 1つの操作ごとに、対応するreferenceを1つだけ読む。
- referenceにない操作はしない。
- 記録済みversionと一致する通常経路では、実行前に`--help`を読まない。
- 未収録操作、version差、構文エラーの場合だけ、対象subcommandの`--help`を読む。
- branch、commit、rebase、pushは`tool-git`スキルへ委譲する。
- 書き込みはIssue、Draft PR、pending review、stacked PRのreferenceに記載された操作だけに限定する。
- reviewのsubmit、threadのresolve、pull requestのReady for review、close、mergeを行わない。
- Actionsのrerun、cancel、deleteを行わない。
- `gh auth token`を実行しない[^gh]。
- repositoryにpull request templateがないことを確認済みの場合は、`assets/pull_request_template.md`をDraft PR本文に使う。
- pending reviewのthread、reply、review bodyへ投稿する本文には、`assets/comment_template.md`を使う。
- CLI referenceの検証結果は[validation](references/validation.md)で確認する。
- GitHubへ本文を渡す前後だけ、専用scriptで権限`0600`の一時body fileを作成、削除する。
- 一時body fileの実装変更時は`scripts/test-private-body-file.sh`で内容、権限、削除対象の境界を確認する。

## Scriptの場所

`<plugin-root>`は、このSkillの配置先から2階層上にあるplugin directoryである。
Claude Codeでは`${CLAUDE_PLUGIN_ROOT}`を使える。
Codexでは利用中のSkill catalogに表示された`tool-gh/SKILL.md`の絶対pathから`<plugin-root>`を解決する。

## ユースケース

**認証とrepository**

| ユースケース | 用途 |
| --- | --- |
| `inspect-authentication` | GitHub hostの認証状態を取得する。 |
| `inspect-repository` | GitHub上の対象repositoryを取得する。 |

**pull request**

| ユースケース | 用途 |
| --- | --- |
| `create-draft-pr` | Draft PRを作る。 |
| `find-pull-request` | head branchを使うpull requestを検索する。 |
| `inspect-pull-request` | pull requestを取得する。 |

**Issue**

| ユースケース | 用途 |
| --- | --- |
| [`add-issue-blocker`](references/add-issue-blocker.md) | Issueへ`blockedBy`関係を追加する。 |
| [`close-issue`](references/close-issue.md) | Issueを完了理由でcloseする。 |
| [`create-issue`](references/create-issue.md) | titleと本文からIssueを一件作る。 |
| [`find-issues`](references/find-issues.md) | titleから作成結果の候補Issueを検索する。 |
| [`prepare-private-body`](references/prepare-private-body.md) | 標準入力から権限`0600`の一時body fileを作る。 |
| [`read-issue`](references/read-issue.md) | Issueの内容、関係、状態を取得する。 |
| [`remove-private-body`](references/remove-private-body.md) | GitHub操作後に専用の一時body fileを削除する。 |
| [`remove-issue-blocker`](references/remove-issue-blocker.md) | Issueから`blockedBy`関係を削除する。 |
| [`reopen-issue`](references/reopen-issue.md) | closeされたIssueをopenへ戻す。 |
| [`set-issue-parent`](references/set-issue-parent.md) | Issueへ親Issueを設定する。 |
| [`unset-issue-parent`](references/unset-issue-parent.md) | Issueから親Issueを外す。 |
| [`update-issue`](references/update-issue.md) | Issueの内容、担当者、labelを更新する。 |

**checkとworkflow**

| ユースケース | 用途 |
| --- | --- |
| `list-workflow-runs` | branchのworkflow runを取得する。 |
| `read-checks` | pull requestのcheckを取得する。 |
| `read-workflow-job` | workflow jobの失敗logを取得する。 |
| `read-workflow-run` | workflow runのjobと失敗logを取得する。 |

**review**

| ユースケース | 用途 |
| --- | --- |
| `add-review-reply` | pending reviewのthreadへreplyを追加する。 |
| `add-review-thread` | pending reviewへinline threadを追加する。 |
| `create-pending-review` | submit前のpending reviewを作る。 |
| `inspect-pending-review` | 認証利用者のpending reviewを取得する。 |
| `read-review-comments` | review body、Conversation comment、inline threadを取得する。 |
| `read-review-thread` | inline threadの全commentを取得する。 |
| `update-review-body` | pending reviewのbodyを更新する。 |

**stacked pull request**

| ユースケース | 用途 |
| --- | --- |
| `inspect-pull-request-stack` | pull requestのstack所属を取得する。 |
| `link-pull-request-stack` | 既存のDraft PRをstackへ関連付ける。 |

[^gh]: [GitHub CLI manual](https://cli.github.com/manual/gh)
