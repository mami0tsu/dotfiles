#!/usr/bin/env bash

set -euo pipefail

# 試験対象、偽のgh command、記録fileを限定的な一時directoryへ用意する。
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
operation_script="$script_dir/github-body-operation.sh"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/github-body-operation-test.XXXXXX")"
fake_bin="$test_root/bin"
mkdir -m 700 "$fake_bin"

# 試験中に作成した限定的な一時directoryだけを削除する。
cleanup() {
  if [[ -n "${test_root:-}" && -d "$test_root" && "$test_root" == "${TMPDIR:-/tmp}/github-body-operation-test."* ]]; then
    rm -rf "$test_root"
  fi
}

trap cleanup EXIT

# 引数、body fileの内容と権限を記録し、指定statusで終了する偽のghを作る。
# 変数はtest生成時ではなく偽commandの実行時に展開するため、意図して単一引用符を使う。
# shellcheck disable=SC2016
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'printf "%s\n" "$@" >"$GH_TEST_ARGS"' \
  'while (($#)); do if [[ "$1" == "--body-file" ]]; then body_file="$2"; break; fi; shift; done' \
  'printf "%s\n" "$body_file" >"$GH_TEST_BODY_PATH"' \
  'cat "$body_file" >"$GH_TEST_BODY"' \
  'if stat -f "%Lp" "$body_file" >/dev/null 2>&1; then stat -f "%Lp" "$body_file" >"$GH_TEST_MODE"; else stat -c "%a" "$body_file" >"$GH_TEST_MODE"; fi' \
  'exit "${GH_TEST_STATUS:-0}"' >"$fake_bin/gh"
chmod 700 "$fake_bin/gh"

# 各操作が本文をprivate fileで渡し、成功後に削除することを確かめる。
for operation in issue-create issue-update pr-create; do
  export GH_TEST_ARGS="$test_root/$operation.args"
  export GH_TEST_BODY_PATH="$test_root/$operation.path"
  export GH_TEST_BODY="$test_root/$operation.body"
  export GH_TEST_MODE="$test_root/$operation.mode"
  case "$operation" in
    issue-create) arguments=(--repo github.example.invalid/owner/repo --title title) ;;
    issue-update) arguments=(--repo github.example.invalid/owner/repo --issue 12 --title title) ;;
    pr-create) arguments=(--repo github.example.invalid/owner/repo --base main --head topic --title title) ;;
  esac
  printf '%s\n' 'private body' | PATH="$fake_bin:$PATH" bash "$operation_script" "$operation" "${arguments[@]}"
  test "$(command cat "$GH_TEST_BODY")" = 'private body'
  test "$(command cat "$GH_TEST_MODE")" = '600'
  grep -Fqx -- 'github.example.invalid/owner/repo' "$GH_TEST_ARGS"
  test ! -e "$(command cat "$GH_TEST_BODY_PATH")"
done

# GitHub操作が失敗しても一時body fileを削除し、失敗statusを返すことを確かめる。
export GH_TEST_ARGS="$test_root/failure.args"
export GH_TEST_BODY_PATH="$test_root/failure.path"
export GH_TEST_BODY="$test_root/failure.body"
export GH_TEST_MODE="$test_root/failure.mode"
export GH_TEST_STATUS=7
if printf '%s\n' 'private body' | PATH="$fake_bin:$PATH" bash "$operation_script" issue-create --repo github.example.invalid/owner/repo --title title; then
  printf '%s\n' 'expected GitHub operation failure' >&2
  exit 1
fi
test ! -e "$(command cat "$GH_TEST_BODY_PATH")"

# Hostを省いたrepositoryを、外部操作を始める前に拒否することを確かめる。
unset GH_TEST_STATUS
if printf '%s\n' 'private body' | PATH="$fake_bin:$PATH" bash "$operation_script" issue-create --repo owner/repo --title title; then
  printf '%s\n' 'expected repository validation failure' >&2
  exit 1
fi

printf '%s\n' 'GitHub body operation tests passed'
