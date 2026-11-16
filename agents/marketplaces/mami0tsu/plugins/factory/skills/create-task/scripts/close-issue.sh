#!/usr/bin/env bash
set -euo pipefail

repo=$(cue export json: "$1" -e roles.issues.repository --out text)
repo=${repo#https://}
repo=${repo%/}
gh issue close "$2" --repo "$repo"
