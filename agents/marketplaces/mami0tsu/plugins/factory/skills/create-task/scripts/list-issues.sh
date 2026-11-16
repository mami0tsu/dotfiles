#!/usr/bin/env bash
set -euo pipefail

repo=$(cue export json: "$1" -e roles.issues.repository --out text)
repo=${repo#https://}
repo=${repo%/}
gh issue list --repo "$repo" --state open --label ready --limit 1000 --json number,title,body,state,labels,url
