# inspect-pending-review

指定したpull requestと認証利用者に属するpending reviewを取得する[^github-graphql]。

## 入力

- `owner/repo`形式のrepository名
- pull request番号

## 出力

- viewer
- pull request ID
- pending review

## 制約

- pending reviewを変更しない。
- pending reviewをID、author、state、commitで識別する。
- pending reviewを本文だけで識別しない。

## 手順

### 1. Pending reviewを取得する

```sh
gh api graphql --paginate \
  -F owner='<owner>' -F name='<repo>' -F number=<pr-number> \
  -f query='
    query($endCursor: String, $owner: String!, $name: String!, $number: Int!) {
      viewer { login }
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          id
          number
          url
          reviews(first: 100, after: $endCursor, states: [PENDING]) {
            nodes { id state author { login } body commit { oid } }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    }
  '
```

### 2. 結果を返す

viewer、pull request ID、pending reviewを返す。

[^github-graphql]: [GitHub CLI `gh api` manual](https://cli.github.com/manual/gh_api)、[GitHub GraphQL pagination guide](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api)
