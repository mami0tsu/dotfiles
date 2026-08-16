# pending review

## 情報源

- 公式ドキュメント：[Pull requests GraphQL reference](https://docs.github.com/en/graphql/reference/pulls)
- 確認対象：`addPullRequestReview`、`addPullRequestReviewThread`、`addPullRequestReviewThreadReply`、`updatePullRequestReview`
- schema 確認コマンド：`gh api graphql`による`__type` query
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- バージョン確認：`gh --version`

## pending review を識別する

### 目的

対象 pull request と認証利用者に属する pending review を取得し、人間が作成した pending review との混在を防ぐ。

### 前提条件

owner、repository、pull request 番号を確定する。

呼び出し元の workflow state に、Agent が作成した pending review ID が記録されているか確認する。

### 推奨コマンド

認証利用者と pending review を取得する。

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

workflow state に review ID がある場合は、返却された `id`、`state: PENDING`、`author.login`、pull request URL、canonical digest が一致する場合だけ再利用する。

review ID がなく、認証利用者の pending review も存在しない場合だけ新規作成へ進む。

### 結果の確認

review ID、pull request ID、URL、認証利用者、head commit OID を workflow state の期待値と照合する。

`reviews.pageInfo.hasNextPage`が`true`なら、全 page を取得してから有無を判断する。

[Actions と review comment](actions-and-review-comments.md) の query で、pending review の body と全 thread、comment、reply を取得する。

thread 内では、`pullRequestReview.id`が記録済み pending review ID と一致する comment だけを snapshot 対象にする。

review body の null と空文字を区別し、対象 thread ID、comment ID、各 body の SHA-256を ID 順に並べた canonical JSON の digest として workflow state に保存する。

snapshot は次の固定 schema にする。

```json
{
  "review": {
    "bodySha256": null,
    "commitOid": "<oid>",
    "id": "<review-id>",
    "state": "PENDING"
  },
  "threads": [
    {
      "comments": [
        {
          "bodySha256": "<sha256>",
          "id": "<comment-id>",
          "state": "PENDING"
        }
      ],
      "id": "<thread-id>",
      "isOutdated": false,
      "isResolved": false
    }
  ]
}
```

review body が null の場合は`bodySha256`を null とし、空文字を含む文字列では UTF-8 byte 列の SHA-256 hex digest を入れる。

thread と comment の配列をそれぞれ ID の byte 順で昇順に並べ、schema にない field を含めない。

JSON は `jq --compact-output --sort-keys`と同じ key 順、escaping、末尾 LF で UTF-8へ直列化し、その byte 列の SHA-256 hex digest を workflow state に保存する。

thread の resolve と outdated の変化も外部変更として検出する。

本文自体は workflow state に保存しない。

各 mutation の直前と成功後に再取得して digest を比較し、期待値と異なる場合は人間の追記または外部変更として停止する。

### 停止条件

workflow state にない認証利用者の pending review が存在する場合は、人間が作成したものとして停止する。

記録済み review が `PENDING`でない場合は再作成せず停止する。

別の利用者が作成した pending review は変更しない。

### 代表的な失敗

pending review が複数返る場合は、review ID を推測せず停止する。

記録済み head commit と現在の head commit が異なる場合は、呼び出し元 flow に再検証を要求する。

## pending review を作成する

### 目的

event を指定せず、submit 前の review を一件作成する。

### 前提条件

pending review の識別手順で、認証利用者の既存 pending review がないことを確認する。

pull request node ID と現在の head commit OID を取得する。

### 推奨コマンド

mutation の `event`を省略する。

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

返却 review ID と空の review 内容から計算した canonical digest は、他の mutation より前に workflow state へ保存する。

### 結果の確認

返却された `state`が`PENDING`であり、author と commit OID が期待値に一致することを確認する。

識別 query を再実行し、同じ review ID を取得できることを確認する。

### 停止条件

`event`を要求する入力は拒否する。

review ID を workflow state へ保存できなかった場合は、追加 mutation を実行せず停止する。

### 代表的な失敗

既存 pending review を示す error が返った場合は再試行せず、識別 query へ戻る。

response が得られた後に中断した場合は新規作成せず、人間に GitHub 上の pending review 確認を求める。

## thread、reply、review body を追加する

### 目的

記録済み pending review にだけ、新規 inline thread、既存 thread への reply、review body を追加する。

### 前提条件

操作ごとに pending review の識別手順と canonical digest の比較を再実行する。

新規 thread では、現在の pull request diff に存在する path、line、side を取得する。

reply では `PullRequestReviewThread.id`を取得し、対象 pull request に属することを確認する。

### 推奨コマンド

新規 thread は、記録済み review ID を `pullRequestReviewId`へ渡す。

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

既存 thread への reply も、記録済み review ID を明示する。

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

review body は、現在値の canonical digest が workflow state と一致することを確認してから全文更新する。

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

### 結果の確認

mutation の返却 object から review ID と state を取得し、記録済み ID と `PENDING`に一致することを確認する。

識別 query と review thread query を再実行し、本文、thread、reply の canonical digest を期待値と比較する。

成功した object ID と更新後 digest を、次の mutation より前に workflow state へ保存する。

### 停止条件

`submitPullRequestReview`、`resolveReviewThread`、`unresolveReviewThread`は実行しない。

`gh pr comment`、`gh pr review`、REST API の review comment endpoint は使わない。

canonical digest が workflow state の期待値と異なる場合は、人間が編集した可能性があるため、追加と更新を行わない。

### 代表的な失敗

line が diff に存在しない場合は、近い行へ移動せず対象を再確認する。

mutation の一部だけが成功した場合は自動削除せず、成功した object ID と現在状態を報告する。
