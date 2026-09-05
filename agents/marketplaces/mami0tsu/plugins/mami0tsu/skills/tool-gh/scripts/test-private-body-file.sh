#!/usr/bin/env bash

set -euo pipefail

# 試験対象と限定的な一時directoryを準備する。
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
body_script="$script_dir/private-body-file.sh"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/private-body-file-test.XXXXXX")"

# 試験中に残った限定的な一時directoryだけを削除する。
cleanup() {
  if [[ -n "${body_file:-}" && -f "$body_file" ]]; then
    bash "$body_script" remove --file "$body_file" || true
  fi
  if [[ -n "${test_root:-}" && -d "$test_root" && "$test_root" == "${TMPDIR:-/tmp}/private-body-file-test."* ]]; then
    rm -rf "$test_root"
  fi
}

trap cleanup EXIT

# 標準入力の本文をprivate fileへ保存し、内容と権限を確かめる。
body_file="$(printf '%s\n' 'private issue body' | bash "$body_script" create)"
test "$(command cat -- "$body_file")" = 'private issue body'
if stat -f '%Lp' "$body_file" >/dev/null 2>&1; then
  test "$(stat -f '%Lp' "$body_file")" = '600'
else
  test "$(stat -c '%a' "$body_file")" = '600'
fi

# 専用fileは削除できるが、管理外のpathは拒否することを確かめる。
bash "$body_script" remove --file "$body_file"
test ! -e "$body_file"
body_file=""
printf '%s\n' 'outside' >"$test_root/outside.md"
if bash "$body_script" remove --file "$test_root/outside.md" >/dev/null 2>&1; then
  printf '%s\n' 'expected unmanaged path removal to fail' >&2
  exit 1
fi

printf '%s\n' 'private body file tests passed'
