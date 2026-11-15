#!/usr/bin/env bash
set -euo pipefail

issue_data=$1
issue_body=$2
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
knap render "$script_dir/../assets/issue_template.md" --data "$issue_data" --output "$issue_body"
