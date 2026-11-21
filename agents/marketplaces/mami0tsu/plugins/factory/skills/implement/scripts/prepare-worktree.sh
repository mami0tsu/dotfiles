#!/usr/bin/env bash
set -euo pipefail

repo=$1
remote=$2
branch=$3
worktree=$4

remote_head=$(git -C "$repo" ls-remote --symref "$remote" HEAD)
default_branch=$(printf '%s\n' "$remote_head" | awk '$1 == "ref:" && $3 == "HEAD" {sub("^refs/heads/", "", $2); print $2}')
[[ -n "$default_branch" && "$default_branch" != *$'\n'* ]]
[[ "$branch" != "$default_branch" ]]
git -C "$repo" fetch "$remote" "$default_branch" >&2
default_path=$(git -C "$repo" wt --nocd "$default_branch" | tail -n 1)
[[ -n "$default_path" ]]
git -C "$default_path" pull --ff-only "$remote" "$default_branch" >&2
remote_head=$(git -C "$repo" ls-remote "$remote" HEAD)
remote_commit=${remote_head%%[[:space:]]*}
[[ $(git -C "$default_path" rev-parse HEAD) == "$remote_commit" ]]

if git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
  worktree_path=$(git -C "$repo" wt --nocd -b "$branch" "$worktree" | tail -n 1)
else
  worktree_path=$(git -C "$repo" wt --nocd -b "$branch" "$worktree" "$remote_commit" | tail -n 1)
fi
[[ $(git -C "$worktree_path" branch --show-current) == "$branch" ]]
printf '%s\n' "$worktree_path"
