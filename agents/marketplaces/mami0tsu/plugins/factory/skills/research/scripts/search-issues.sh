#!/usr/bin/env bash
set -euo pipefail

config=$1
query=$2
ideas_repo=$(cue export json: "$config" -e roles.ideas.repository --out text)
ideas_repo=${ideas_repo#https://}
ideas_repo=${ideas_repo%/}
gh issue list --repo "$ideas_repo" --state all --search "$query" --limit 1000 --json number,title,body,state,url
