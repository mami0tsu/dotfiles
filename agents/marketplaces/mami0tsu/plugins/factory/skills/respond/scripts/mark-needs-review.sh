#!/usr/bin/env bash
set -euo pipefail

config=$1
issue_url=$2
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
schema="$script_dir/../../init/assets/config.cue"
research=$(cue export "$schema" json: "$config" -e states.issues.needsResearch --out text)
review=$(cue export "$schema" json: "$config" -e states.issues.needsReview --out text)
accepted=$(cue export "$schema" json: "$config" -e states.issues.accepted --out text)
rejected=$(cue export "$schema" json: "$config" -e states.issues.rejected --out text)
current=$(gh issue view "$issue_url" --json state,labels --jq '.state, .labels[].name')
[[ ${current%%$'\n'*} == OPEN ]]
current=$'\n'"$current"$'\n'
[[ "$current" != *$'\n'"$review"$'\n'* && "$current" != *$'\n'"$accepted"$'\n'* && "$current" != *$'\n'"$rejected"$'\n'* ]]
if [[ "$current" == *$'\n'"$research"$'\n'* ]]; then
  gh issue edit "$issue_url" --remove-label "$research" --add-label "$review"
else
  gh issue edit "$issue_url" --add-label "$review"
fi
