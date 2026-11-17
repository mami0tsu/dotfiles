#!/usr/bin/env bash
set -euo pipefail

gh pr create --repo "$1" --base "$2" --head "$3" --title "$4" --body-file "$5" --draft
