#!/usr/bin/env bash
set -euo pipefail

config=$1
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
schema="$script_dir/../skills/init/assets/config.cue"
search=""
for state in accepted rejected; do
  label=$(cue export "$schema" json: "$config" -e "states.issues.$state" --out text)
  label=${label//\\/\\\\}
  label=${label//\"/\\\"}
  search+=" -label:\"$label\""
done
limit=$(cue export json: "$config" -e loop.skills.inspect.maxOpenIssues)
issues_repo=$(cue export json: "$config" -e roles.issues.repository --out text)
issues_repo=${issues_repo#https://}
issues_repo=${issues_repo%/}
if ! count=$(gh issue list --repo "$issues_repo" --state open --search "$search" --limit "$limit" --json number --jq 'length'); then
  exit 1
fi
if (( count >= limit )); then
  printf '%s\n' 'The inspect Issue limit has been reached.' >&2
  exit 2
fi
