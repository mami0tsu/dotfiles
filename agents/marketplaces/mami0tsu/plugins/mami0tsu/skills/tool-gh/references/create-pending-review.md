# create-pending-review

指定したpull requestへsubmit前のpending reviewを作る[^github-graphql]。

## 入力

- pull requestのnode ID
- head commit OID
- `inspect-pending-review`ユースケースの空の検索結果

## 出力

- pending review ID
- state
- author
- commit OID

## 制約

- mutationへeventを渡さない。
- 既存のpending reviewを変更しない。
- submitを行わない。

## 手順

### 1. Pending reviewを作る

```sh
gh api graphql \
  -F pullRequestId='<pull-request-node-id>' \
  -F commitOID='<head-commit-oid>' \
  -f query='
    mutation($pullRequestId: ID!, $commitOID: GitObjectID!) {
      addPullRequestReview(input: {
        pullRequestId: $pullRequestId,
        commitOID: $commitOID
      }) {
        pullRequestReview { id state author { login } commit { oid } }
      }
    }
  '
```

### 2. 結果を返す

pending review ID、state、author、commit OIDを返す。

[^github-graphql]: [GitHub CLI `gh api` manual](https://cli.github.com/manual/gh_api)、[GitHub GraphQL pull request reference](https://docs.github.com/en/graphql/reference/pulls)
