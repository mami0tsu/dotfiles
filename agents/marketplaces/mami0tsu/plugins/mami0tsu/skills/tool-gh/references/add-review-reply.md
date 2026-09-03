# add-review-reply

指定したpending reviewのinline threadへreplyを追加する[^github-graphql]。

## 入力

- pending review ID
- review thread ID
- body file

## 出力

- comment ID
- pending review ID

## 制約

- review threadは対象pull requestに属するものとする。
- replyを即時公開しない。

## 手順

### 1. Replyを追加する

```sh
gh api graphql \
  -F reviewId='<pending-review-id>' -F threadId='<review-thread-id>' \
  -F body=@<body-file> \
  -f query='
    mutation($reviewId: ID!, $threadId: ID!, $body: String!) {
      addPullRequestReviewThreadReply(input: {
        pullRequestReviewId: $reviewId,
        pullRequestReviewThreadId: $threadId,
        body: $body
      }) {
        comment { id state body pullRequestReview { id state } }
      }
    }
  '
```

### 2. 結果を返す

comment IDとpending review IDを返す。

[^github-graphql]: [GitHub CLI `gh api` manual](https://cli.github.com/manual/gh_api)、[GitHub GraphQL pull request reference](https://docs.github.com/en/graphql/reference/pulls)
