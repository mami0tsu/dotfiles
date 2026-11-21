#!/usr/bin/env bash
set -euo pipefail

printf '{}' | gh api --method POST "repos/$1/pulls/$2/reviews" --input - --jq '.node_id'
