#!/usr/bin/env bash
set -euo pipefail

git -C "$1" push "$2" "$3"
