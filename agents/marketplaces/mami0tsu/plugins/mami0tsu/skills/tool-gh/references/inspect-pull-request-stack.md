# inspect-pull-request-stack

指定したpull requestのstack所属を取得する[^github-stacks]。

## 入力

- `owner/repo`形式のrepository名
- pull request番号

## 出力

- pull request番号
- pull request URL
- stack
- stack entry

## 制約

- pull requestとstackを変更しない。
- GraphQL mutationを実行しない。

## 手順

### 1. Stack所属を取得する

```sh
gh api graphql \
  -F owner='<owner>' -F name='<repo>' -F number=<pr-number> \
  -f query='
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          number
          url
          stack { id number baseRefName size }
          stackEntry { id position stack { id number } }
        }
      }
    }
  '
```

### 2. 結果を返す

pull request番号、URL、stack、stack entryを返す。

[^github-stacks]: [GitHub Stacked Pull Requests](https://gh.io/stacks)
