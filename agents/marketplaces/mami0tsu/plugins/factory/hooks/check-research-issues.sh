#!/usr/bin/env bash
set -euo pipefail

config=$1
limit=$(cue export json: "$config" -e loop.skills.research.maxOpenIssues)
issues_repo=$(cue export json: "$config" -e roles.issues.repository --out text)
issues_repo=${issues_repo#https://}
issues_repo=${issues_repo%/}
if ! count=$(gh issue list --repo "$issues_repo" --state open --limit "$limit" --json number --jq 'length'); then
  exit 1
fi
if (( count >= limit )); then
  printf '%s\n' 'The research Issue limit has been reached.' >&2
  exit 2
fi
