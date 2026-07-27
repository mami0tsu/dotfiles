# Actions と review comment

## 情報源

- 公式ドキュメント：[gh pr checks](https://cli.github.com/manual/gh_pr_checks)（確認コマンド：`gh pr checks --help`）
- 公式ドキュメント：[gh run list](https://cli.github.com/manual/gh_run_list)（確認コマンド：`gh run list --help`）
- 公式ドキュメント：[gh run view](https://cli.github.com/manual/gh_run_view)（確認コマンド：`gh run view --help`）
- 公式ドキュメント：[gh api](https://cli.github.com/manual/gh_api)（確認コマンド：`gh api --help`）
- 公式ドキュメント：[Pull requests GraphQL reference](https://docs.github.com/en/graphql/reference/pulls)（確認対象：`PullRequest` の `number`、`url`、`reviewThreads`、`PullRequestReviewThread` の `comments`、`isResolved`、`isOutdated`、`path`、`line`、`originalLine`、`diffSide`、`PullRequestReviewComment` の `author`、`body`、`createdAt`、`url`、`commit`、`originalCommit`）
- GraphQL の field 確認コマンド：`gh api graphql -f query='query { pullRequest: __type(name: "PullRequest") { fields { name } } thread: __type(name: "PullRequestReviewThread") { fields { name } } comment: __type(name: "PullRequestReviewComment") { fields { name } } }'`
- GraphQL のページネーション構文確認：`gh api graphql --help`
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- バージョン確認：`gh --version`

## GitHub Actions を読む

### 目的

pull request に属する check の状態を確認し、必要な workflow run と失敗したログを特定する。

### 前提条件

pull request に属する check を調べる場合は、pull request 番号または URL を取得する。

branch 単位で workflow run を調べる場合は、branch 名を取得する。

### 推奨コマンド

pull request の check を読むときは、次を使う。

```sh
gh pr checks <number-or-url> --repo <owner>/<repo> \
  --json name,state,bucket,workflow,link
```

`bucket` は `pass`、`fail`、`pending`、`skipping`、`cancel` の分類に使う。

pending の check は exit code 8 を返すため、失敗として扱わず状態を報告する。

workflow run を絞るときは、branch と必要な field を指定する。

```sh
gh run list --repo <owner>/<repo> --branch <branch> --limit 20 \
  --json databaseId,workflowName,status,conclusion,headSha,createdAt,url
```

特定した run の job と失敗した step を読むときは、次を使う。

```sh
gh run view <run-id> --repo <owner>/<repo> \
  --json databaseId,workflowName,status,conclusion,jobs,url
gh run view <run-id> --repo <owner>/<repo> --log-failed
```

### 結果の確認

check ごとに `name`、`state`、`bucket`、`link` を確認する。

run を扱う場合は、`databaseId`、`workflowName`、`status`、`conclusion`、`headSha` が対象 branch または pull request の commit と一致することを確認する。

失敗ログでは、失敗した job、step、最初の原因を分けて報告する。

### 停止条件

rerun、cancel、delete、workflow の有効化または無効化は実行しない。

同じ branch に複数の run がある場合は、`headSha` と `createdAt` で対象を絞る。

ログに token、credential、個人情報が含まれる場合は、その値を出力または共有せず、利用者へ報告する。

### 代表的な失敗

`gh pr checks` が exit code 8 を返す場合は、check が pending である。

`gh run view --log-failed` が job と log を結び付けられない場合は、対象 job を `--job <job-id>` で指定して再実行する。

run が見つからない場合は、branch、head SHA、workflow 名、対象 repository を確認する。

## review comment を読む

### 目的

pull request の inline review comment、解決状態、outdated 状態、対象 path を取得する。

### 前提条件

repository owner、repository 名、pull request 番号を取得する。

review comment は `gh pr review` では読まない。

`gh pr review` は review を投稿する書き込み操作であるため、read-only の GraphQL query を使う。

### 推奨コマンド

review thread をページングしながら取得する。

```sh
gh api graphql --paginate \
  -F owner='<owner>' -F name='<repo>' -F number=<pr-number> \
  -f query='
    query($endCursor: String, $owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          number
          url
          reviewThreads(first: 100, after: $endCursor) {
            nodes {
              isResolved
              isOutdated
              path
              line
              originalLine
              diffSide
              comments(first: 100) {
                nodes {
                  author { login }
                  body
                  createdAt
                  url
                  commit { oid }
                  originalCommit { oid }
                }
                pageInfo { hasNextPage }
              }
            }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    }
  '
```

thread ごとに、`isResolved`、`isOutdated`、`path`、`line`、`originalLine`、`diffSide` を読む。

comment ごとに、`author.login`、`body`、`createdAt`、`url`、`commit.oid`、`originalCommit.oid` を読む。

### 結果の確認

返された pull request の `number` と `url` が、指定した番号と対象 URL に一致することを確認する。

未解決 thread は `isResolved: false`、古い diff に属する thread は `isOutdated: true` として区別する。

`comments.pageInfo.hasNextPage` が `true` の thread は、1 回の query で全 comment を取得できていない。

### 停止条件

コメントへの返信、resolve または unresolve、review の投稿は実行しない。

`comments.pageInfo.hasNextPage` が `true` の場合は、必要な追加取得方法を利用者へ確認する。

GraphQL query の実行は HTTP POST になるが、mutation を含まない query は読み取り操作として扱う。

### 代表的な失敗

`reviewThreads` が空の場合は、inline review comment が存在しないか、閲覧権限が不足している可能性がある。

GraphQL の field error が出た場合は、`gh api --help` ではなく GraphQL object reference と対象 query の field を確認する。

pagination の結果が複数の JSON object になる場合は、page ごとに `reviewThreads.pageInfo.endCursor` が進んでいることを確認する。
