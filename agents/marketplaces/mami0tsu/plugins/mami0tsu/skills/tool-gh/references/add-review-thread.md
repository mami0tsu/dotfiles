# add-review-thread

指定したpending reviewへinline review threadを追加する[^github-graphql]。

## 入力

- pending review ID
- path
- line
- diff side
- body file

## 出力

- thread ID
- comment ID
- pending review ID

## 制約

- path、line、diff sideは現在のpull request diffに存在するものとする。
- commentを即時公開しない。

## 手順

### 1. Inline review threadを追加する

```sh
gh api graphql \
  -F reviewId='<pending-review-id>' -F path='<path>' \
  -F line=<line> -F side='<LEFT-or-RIGHT>' -F body=@<body-file> \
  -f query='
    mutation($reviewId: ID!, $path: String!, $line: Int!, $side: DiffSide!, $body: String!) {
      addPullRequestReviewThread(input: {
        pullRequestReviewId: $reviewId,
        path: $path,
        line: $line,
        side: $side,
        body: $body
      }) {
        thread {
          id
          path
          line
          diffSide
          comments(first: 1) {
            nodes { id state body pullRequestReview { id state } }
          }
        }
      }
    }
  '
```

### 2. 結果を返す

thread ID、comment ID、pending review IDを返す。

[^github-graphql]: [GitHub CLI `gh api` manual](https://cli.github.com/manual/gh_api)、[GitHub GraphQL pull request reference](https://docs.github.com/en/graphql/reference/pulls)
