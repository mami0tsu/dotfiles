# update-review-body

指定したpending reviewのbodyを更新する[^github-graphql]。

## 入力

- pending review ID
- body file

## 出力

- pending review ID
- body

## 制約

- bodyは全文を入力する。
- pending reviewをsubmitしない。

## 手順

### 1. Review bodyを更新する

```sh
gh api graphql \
  -F reviewId='<pending-review-id>' -F body=@<body-file> \
  -f query='
    mutation($reviewId: ID!, $body: String!) {
      updatePullRequestReview(input: {
        pullRequestReviewId: $reviewId,
        body: $body
      }) {
        pullRequestReview { id state body }
      }
    }
  '
```

### 2. 結果を返す

pending review IDとbodyを返す。

[^github-graphql]: [GitHub CLI `gh api` manual](https://cli.github.com/manual/gh_api)、[GitHub GraphQL pull request reference](https://docs.github.com/en/graphql/reference/pulls)
