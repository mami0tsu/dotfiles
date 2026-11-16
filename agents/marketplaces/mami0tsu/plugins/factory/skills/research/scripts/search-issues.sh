#!/usr/bin/env bash
set -euo pipefail

config=$1
query=$2
issues_repo=$(cue export json: "$config" -e roles.issues.repository --out text)
issues_repo=${issues_repo#https://}
issues_repo=${issues_repo%/}
gh issue list --repo "$issues_repo" --state all --search "$query" --limit 1000 --json number,title,body,state,url
