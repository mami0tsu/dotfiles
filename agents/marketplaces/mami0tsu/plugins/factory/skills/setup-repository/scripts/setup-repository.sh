#!/usr/bin/env bash
set -euo pipefail

repo_url=$1
repo_key=${repo_url#https://}
repo_key=${repo_key#http://}
repo_key=${repo_key#ssh://}
repo_key=${repo_key#git@}
repo_key=${repo_key/:/\/}
repo_key=${repo_key%/}
repo_key=${repo_key%.git}
ghq get "$repo_url" >&2
repo_path=$(ghq list --full-path --exact "$repo_key")
[[ -n "$repo_path" && "$repo_path" != *$'\n'* ]]
branch=$(gh repo view "$repo_url" --json defaultBranchRef | cue export json: - -e defaultBranchRef.name --out text)
git -C "$repo_path" switch "$branch" >&2
git -C "$repo_path" pull --ff-only "$repo_url" "$branch" >&2
commit=$(git -C "$repo_path" rev-parse HEAD)
printf '%s\n%s\n' "$repo_path" "$commit"
