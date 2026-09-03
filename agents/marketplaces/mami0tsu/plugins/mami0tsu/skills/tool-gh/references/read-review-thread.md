# read-review-thread

指定したinline review threadの全commentを取得する[^github-graphql]。

## 入力

- review threadのnode ID

## 出力

- thread ID
- 全comment
- pagination情報

## 制約

- review threadとcommentを変更しない。
- GraphQL mutationを実行しない。

## 手順

### 1. Commentを取得する

```sh
gh api graphql --paginate \
  -F threadId='<review-thread-node-id>' \
  -f query='
    query($endCursor: String, $threadId: ID!) {
      node(id: $threadId) {
        ... on PullRequestReviewThread {
          id
          comments(first: 100, after: $endCursor) {
            nodes {
              id
              author { login }
              body
              state
              createdAt
              url
              pullRequestReview { id state }
              commit { oid }
              originalCommit { oid }
            }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    }
  '
```

### 2. 結果を返す

thread ID、全comment、pageInfoを返す。

[^github-graphql]: [GitHub CLI `gh api` manual](https://cli.github.com/manual/gh_api)、[GitHub GraphQL pagination guide](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api)
