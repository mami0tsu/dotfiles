#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cue export json: "$1" -e roles.ideas.repository --out text)
repo=${repo#https://}
repo=${repo%/}
labels=$(sed -n 's/^{# labels: \(.*\) #}$/\1/p' "$script_dir/../../research/assets/issue_template.md")
gh issue list --repo "$repo" --state open --label "$labels" --label ready --limit 1000 --json number,title,body,state,labels,url
