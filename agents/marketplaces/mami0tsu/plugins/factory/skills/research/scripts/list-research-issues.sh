#!/usr/bin/env bash
set -euo pipefail

issues_repo=$(cue export json: "$1" -e roles.issues.repository --out text)
issues_repo=${issues_repo#https://}
issues_repo=${issues_repo%/}
gh issue list --repo "$issues_repo" --state open --limit 1000 --json url
