#!/usr/bin/env bash
set -euo pipefail

gh api --method POST "repos/$1/issues/$2/comments" -F "body=@$3"
