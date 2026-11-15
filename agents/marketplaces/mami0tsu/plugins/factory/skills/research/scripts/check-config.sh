#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
schema="$script_dir/../../init/assets/config.cue"
config=$1

cue export json: "$config" -e repositories | cue vet -c "$schema" json: - -d repositories
count=$(cue export json: "$config" -e 'len(repositories)')
if (( count == 0 )); then
  printf '%s\n' 'repositories must contain at least one repository' >&2
  exit 1
fi
cue export json: "$config" -e roles.ideas.repository | cue vet -c "$schema" json: - -d roles.ideas.repository
