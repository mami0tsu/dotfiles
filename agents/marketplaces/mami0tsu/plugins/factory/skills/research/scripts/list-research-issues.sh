#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
schema="$script_dir/../../init/assets/config.cue"
search=' -label:"ready"'
for state in needsReview accepted rejected; do
  label=$(cue export "$schema" json: "$1" -e "states.issues.$state" --out text)
  label=${label//\\/\\\\}
  label=${label//\"/\\\"}
  search+=" -label:\"$label\""
done
issues_repo=$(cue export json: "$1" -e roles.issues.repository --out text)
issues_repo=${issues_repo#https://}
issues_repo=${issues_repo%/}
gh issue list --repo "$issues_repo" --state open --search "$search" --limit 1000 --json url
