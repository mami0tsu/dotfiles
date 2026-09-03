# read-review-comments

指定したpull requestのreview body、Conversation comment、inline review threadを取得する[^github-graphql]。

## 入力

- `owner/repo`形式のrepository名
- pull request番号

## 出力

- review body
- Conversation comment
- inline review thread
- threadとcommentのpagination情報

## 制約

- pull requestとreviewを変更しない。
- GraphQL mutationを実行しない。
- review、Conversation comment、inline review commentをIDとURLで区別する。

## 手順

### 1. Review bodyとConversation commentを取得する

```sh
gh pr view <pr-number> --repo <owner>/<repo> \
  --json number,url,reviews,comments
```

### 2. Inline review threadを取得する

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
              id
              isResolved
              isOutdated
              viewerCanReply
              path
              line
              originalLine
              diffSide
              comments(first: 100) {
                nodes {
                  id
                  author { login }
                  body
                  createdAt
                  url
                  state
                  pullRequestReview { id state }
                  commit { oid }
                  originalCommit { oid }
                }
                pageInfo { hasNextPage endCursor }
              }
            }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    }
  '
```

### 3. 結果を返す

review body、Conversation comment、inline review thread、各pageInfoを返す。

[^github-graphql]: [GitHub CLI `gh api` manual](https://cli.github.com/manual/gh_api)、[GitHub GraphQL pagination guide](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api)
