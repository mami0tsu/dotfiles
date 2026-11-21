#!/usr/bin/env bash
set -euo pipefail

gh api --paginate 'notifications?all=true&per_page=100'
