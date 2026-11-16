#!/usr/bin/env bash
set -euo pipefail

gh search prs --review-requested @me --state open --draft=false --limit 1000 --json number,repository,title,url
