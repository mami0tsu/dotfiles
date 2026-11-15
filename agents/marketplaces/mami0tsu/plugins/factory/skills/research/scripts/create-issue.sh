#!/usr/bin/env bash
set -euo pipefail

config=$1
issue_title=$2
issue_body=$3
issue_labels=$4
ideas_repo=$(cue export json: "$config" -e roles.ideas.repository --out text)
ideas_repo=${ideas_repo#https://}
ideas_repo=${ideas_repo%/}
gh issue create --repo "$ideas_repo" --title "$issue_title" --body-file "$issue_body" --label "$issue_labels"
