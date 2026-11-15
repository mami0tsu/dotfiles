#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config=$1
limit=$(cue export json: "$config" -e loop.skills.research.maxOpenIssues)
ideas_repo=$(cue export json: "$config" -e roles.ideas.repository --out text)
ideas_repo=${ideas_repo#https://}
ideas_repo=${ideas_repo%/}
labels=$(sed -n 's/^{# labels: \(.*\) #}$/\1/p' "$script_dir/../skills/research/assets/issue_template.md")
if ! count=$(gh issue list --repo "$ideas_repo" --state open --label "$labels" --limit "$limit" --json number --jq 'length'); then
  exit 1
fi
if (( count >= limit )); then
  printf '%s\n' 'The research Issue limit has been reached.' >&2
  exit 2
fi
