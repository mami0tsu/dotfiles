#!/usr/bin/env bash
set -eu

worktree_path="${1:?usage: inspect-worktree.sh <worktree-path>}"
repository_root="$(git -C "$worktree_path" rev-parse --show-toplevel)"

printf 'repository_root\t%s\n' "$repository_root"
printf 'branch\t%s\n' "$(git -C "$repository_root" branch --show-current)"
printf 'head\t%s\n' "$(git -C "$repository_root" rev-parse HEAD)"
printf 'status\n'
git -C "$repository_root" status --porcelain=v1 --branch
