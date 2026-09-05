#!/usr/bin/env bash

set -euo pipefail

# 試験対象と限定的な一時directoryを準備する。
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
digest_script="$script_dir/artifact-digest.sh"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/artifact-digest-test.XXXXXX")"

# 試験中に作成した限定的な一時directoryだけを削除する。
cleanup() {
  if [[ -n "${test_root:-}" && -d "$test_root" && "$test_root" == "${TMPDIR:-/tmp}/artifact-digest-test."* ]]; then
    rm -rf "$test_root"
  fi
}

trap cleanup EXIT

# 同じtextを異なる改行形式と末尾改行数で用意する。
printf 'alpha\nbeta\n' >"$test_root/text-lf.txt"
printf 'alpha\r\nbeta\r\n\r\n' >"$test_root/text-crlf.txt"
printf 'alpha\rbeta' >"$test_root/text-cr.txt"
chmod 600 "$test_root"/text-*.txt

# 改行表現が異なってもtext digestが一致することを確かめる。
text_digest="$(bash "$digest_script" text --file "$test_root/text-lf.txt")"
test "$text_digest" = "$(bash "$digest_script" text --file "$test_root/text-crlf.txt")"
test "$text_digest" = "$(bash "$digest_script" text --file "$test_root/text-cr.txt")"
test "$text_digest" = "$(printf 'alpha\nbeta' | bash "$digest_script" text)"

# 同じJSONを異なるkey順と空白で用意する。
printf '%s\n' '{"beta":[2,1],"alpha":{"enabled":true}}' >"$test_root/compact.json"
printf '%s\n' '{ "alpha": { "enabled": true }, "beta": [2, 1] }' >"$test_root/formatted.json"
printf '%s\n' '{invalid-json' >"$test_root/invalid.json"
chmod 600 "$test_root"/*.json

# key順と空白が異なってもJSON digestが一致することを確かめる。
json_digest="$(bash "$digest_script" json --file "$test_root/compact.json")"
test "$json_digest" = "$(bash "$digest_script" json --file "$test_root/formatted.json")"
test "$json_digest" = "$(printf '%s' '{"beta":[2,1],"alpha":{"enabled":true}}' | bash "$digest_script" json)"

# JSONとして解釈できない入力と公開権限のfileを拒否することを確かめる。
if bash "$digest_script" json --file "$test_root/invalid.json" >/dev/null 2>&1; then
  printf '%s\n' 'expected invalid JSON to fail' >&2
  exit 1
fi
chmod 644 "$test_root/formatted.json"
if bash "$digest_script" json --file "$test_root/formatted.json" >/dev/null 2>&1; then
  printf '%s\n' 'expected public input file to fail' >&2
  exit 1
fi

printf '%s\n' 'artifact digest tests passed'
