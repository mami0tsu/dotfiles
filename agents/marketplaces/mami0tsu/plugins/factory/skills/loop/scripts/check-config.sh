#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cue export "$script_dir/../../init/assets/config.cue" json: "$1" -e loop
