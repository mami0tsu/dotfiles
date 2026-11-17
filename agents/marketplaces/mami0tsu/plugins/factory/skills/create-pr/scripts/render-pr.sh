#!/usr/bin/env bash
set -euo pipefail

knap render "$1" --data "$2" --output "$3"
