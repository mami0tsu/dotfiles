---
name: tool-gh
description: >-
  GitHub CLIを使い、GitHub上のrepository、pull request、Actions、review commentを読み取り、Draft PR、pending review、stacked PRを扱うためのTool。
  GitHub上の情報を確認し、対応する操作を行うときに使う。
allowed-tools: >-
  Bash(gh api graphql --paginate *)
  Bash(gh api graphql -F owner=* -F name=* -F number=* -f query=*)
  Bash(gh api graphql -F pullRequestId=* -F commitOID=* -f query=*)
  Bash(gh api graphql -F reviewId=* -F body=@* -f query=*)
  Bash(gh api graphql -F reviewId=* -F path=* -F line=* -F side=* -F body=@* -f query=*)
  Bash(gh api graphql -F reviewId=* -F threadId=* -F body=@* -f query=*)
  Bash(gh auth status --hostname *)
  Bash(gh pr checks * --repo * --json name,state,bucket,workflow,link)
  Bash(gh pr create --repo * --draft --base * --head * --title * --body-file *)
  Bash(gh pr list --repo * --head * --state all --json number,state,isDraft,baseRefName,headRefName,title,url)
  Bash(gh pr view * --repo * --json number,isDraft,baseRefName,headRefName,title,body,url)
  Bash(gh pr view * --repo * --json number,state,isDraft,author,baseRefName,headRefName,headRefOid,commits,title,body,reviewDecision,mergeStateStatus,changedFiles,additions,deletions,files,statusCheckRollup,url)
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

- 一つの操作ごとに、対応するreferenceを1つだけ読む。
- referenceにない操作を実行しない。
- branch、commit、rebase、pushは`tool-git`スキルへ委譲する。
- 書き込みはDraft PR、pending review、stacked PRのreferenceに記載された操作だけに限定する。
- reviewのsubmit、threadのresolve、pull requestのReady for review、close、mergeを行わない。
- Actionsのrerun、cancel、deleteを行わない。
- `gh auth token`を実行しない[^gh]。
- repositoryにpull request templateがないことを確認済みの場合は、`assets/pull_request_template.md`をDraft PR本文に使う。
- pending reviewのthread、reply、review bodyへ投稿する本文には、`assets/comment_template.md`を使う。

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
