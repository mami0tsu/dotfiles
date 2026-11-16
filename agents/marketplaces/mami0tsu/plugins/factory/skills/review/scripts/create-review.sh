#!/usr/bin/env bash
set -euo pipefail

jq 'del(.event)' "$3" | gh api --method POST "repos/$1/pulls/$2/reviews" --input -
