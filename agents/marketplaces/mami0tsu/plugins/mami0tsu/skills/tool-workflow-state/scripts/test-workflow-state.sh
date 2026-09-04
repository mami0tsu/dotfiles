#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
state_script="$script_dir/workflow-state.sh"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/workflow-state-test.XXXXXX")"
repository="$test_root/repository"
linked_worktree="$test_root/linked"
value_file="$test_root/value.json"
result_file="$test_root/result.json"
secret_file="$test_root/secret.json"

cleanup() {
  if [[ -n "${test_root:-}" && -d "$test_root" && "$test_root" == "${TMPDIR:-/tmp}/workflow-state-test."* ]]; then
    rm -rf "$test_root"
  fi
}

trap cleanup EXIT

git init -q "$repository"
git -C "$repository" -c user.name=Codex -c user.email=codex@example.invalid commit --allow-empty -m init -q
git -C "$repository" branch secondary
git -C "$repository" worktree add -q "$linked_worktree" secondary

jq -n '{canonical_url:"https://example.invalid/design", digest:"sha256:test"}' >"$value_file"
jq -n '{issue_url:"https://example.invalid/issues/1"}' >"$result_file"
jq -n '{access_token:"prohibited"}' >"$secret_file"
chmod 600 "$value_file" "$result_file" "$secret_file"

(
  cd "$repository"
  bash "$state_script" init \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject req-1 >/dev/null
)

(
  cd "$linked_worktree"
  bash "$state_script" verify \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject req-1 >/dev/null
  bash "$state_script" update \
    --workflow-id test-design \
    --namespace publication \
    --expected-revision 0 \
    --value-file "$value_file" >/dev/null
)

if (
  cd "$repository"
  bash "$state_script" update \
    --workflow-id test-design \
    --namespace publication \
    --expected-revision 0 \
    --value-file "$value_file" >/dev/null 2>&1
); then
  printf '%s\n' 'expected stale revision to fail' >&2
  exit 1
fi

if (
  cd "$repository"
  bash "$state_script" update \
    --workflow-id test-design \
    --namespace credentials \
    --expected-revision 1 \
    --value-file "$secret_file" >/dev/null 2>&1
); then
  printf '%s\n' 'expected prohibited field to fail' >&2
  exit 1
fi

(
  cd "$repository"
  bash "$state_script" complete \
    --workflow-id test-design \
    --expected-revision 1 \
    --result-file "$result_file" >/dev/null
  test "$(jq -r '.status' .git/agent-workflows/test-design.json)" = 'completed'
  test "$(jq -r '.revision' .git/agent-workflows/test-design.json)" = '2'
)

printf '%s\n' 'workflow-state tests passed'
