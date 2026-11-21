#!/usr/bin/env bash
set -euo pipefail

config=$1
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if cue export json: "$config" -e loop.skills.research.maxOpenIssues >/dev/null 2>&1; then
  bash "$script_dir/../../../hooks/check-research-issues.sh" "$config"
fi
issue_title=$2
issue_body=$3
issues_repo=$(cue export json: "$config" -e roles.issues.repository --out text)
issues_repo=${issues_repo#https://}
issues_repo=${issues_repo%/}
gh issue create --repo "$issues_repo" --title "$issue_title" --body-file "$issue_body"
