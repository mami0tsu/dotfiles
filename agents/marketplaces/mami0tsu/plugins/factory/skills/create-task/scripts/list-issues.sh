#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
label=$(cue export "$script_dir/../../init/assets/config.cue" json: "$1" -e states.issues.accepted --out text)
repo=$(cue export json: "$1" -e roles.issues.repository --out text)
repo=${repo#https://}
repo=${repo%/}
gh issue list --repo "$repo" --state open --label "$label" --limit 1000 --json number,title,body,state,labels,url
