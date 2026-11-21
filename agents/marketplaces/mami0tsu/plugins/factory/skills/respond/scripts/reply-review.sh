#!/usr/bin/env bash
set -euo pipefail

gh api graphql -F "reviewId=$1" -F "threadId=$2" -F "body=@$3" -f query='
  mutation($reviewId: ID!, $threadId: ID!, $body: String!) {
    addPullRequestReviewThreadReply(input: {
      pullRequestReviewId: $reviewId,
      pullRequestReviewThreadId: $threadId,
      body: $body
    }) {
      comment { id url state pullRequestReview { id state } }
    }
  }
'
