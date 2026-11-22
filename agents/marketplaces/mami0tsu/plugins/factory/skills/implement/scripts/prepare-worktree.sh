#!/usr/bin/env bash
set -euo pipefail

repo=$1
branch=$2
worktree=$3
commit=$4

if git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
  worktree_path=$(git -C "$repo" wt --nocd -b "$branch" "$worktree" | tail -n 1)
else
  worktree_path=$(git -C "$repo" wt --nocd -b "$branch" "$worktree" "$commit" | tail -n 1)
fi
[[ $(git -C "$worktree_path" branch --show-current) == "$branch" ]]
printf '%s\n' "$worktree_path"
