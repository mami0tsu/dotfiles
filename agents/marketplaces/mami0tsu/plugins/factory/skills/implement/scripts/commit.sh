#!/usr/bin/env bash
set -euo pipefail

repo=$1
message=$2
shift 2
(( $# > 0 ))
git -C "$repo" diff --cached --quiet
git -C "$repo" add -- "$@"
git -C "$repo" diff --cached --check
git -C "$repo" commit -m "$message"
