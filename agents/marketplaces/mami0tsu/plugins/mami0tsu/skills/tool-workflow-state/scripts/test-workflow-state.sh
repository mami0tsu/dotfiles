#!/usr/bin/env bash

set -euo pipefail

# 一時repositoryと検証用JSONの配置先を準備する。
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
state_script="$script_dir/workflow-state.sh"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/workflow-state-test.XXXXXX")"
repository="$test_root/repository"
linked_worktree="$test_root/linked"
other_repository="$test_root/other-repository"
value_file="$test_root/value.json"
delta_file="$test_root/delta.json"
result_file="$test_root/result.json"
secret_file="$test_root/secret.json"
invalid_result_file="$test_root/invalid-result.json"
invalid_digest_file="$test_root/invalid-digest.json"
invalid_type_file="$test_root/invalid-type.json"
invalid_url_file="$test_root/invalid-url.json"
lock_ready="$test_root/lock-ready"
holder_pid=""
subject_digest="sha256:0000000000000000000000000000000000000000000000000000000000000000"
other_subject_digest="sha256:1111111111111111111111111111111111111111111111111111111111111111"

# 試験中に作成した限定的な一時directoryだけを削除する。
cleanup() {
  if [[ "${holder_pid:-}" =~ ^[0-9]+$ ]] && kill -0 "$holder_pid" 2>/dev/null; then
    kill "$holder_pid" 2>/dev/null || true
    wait "$holder_pid" 2>/dev/null || true
  fi
  if [[ -n "${test_root:-}" && -d "$test_root" && "$test_root" == "${TMPDIR:-/tmp}/workflow-state-test."* ]]; then
    rm -rf "$test_root"
  fi
}

# OSに応じたfile lockを保持し、取得完了を呼び出し元へ通知する。
hold_test_lock() {
  local lock_file="$1" ready_file="$2"
  if command -v lockf >/dev/null 2>&1; then
    lockf -k "$lock_file" sh -c "touch \"\$1\"; sleep 1" sh "$ready_file"
  else
    flock "$lock_file" sh -c "touch \"\$1\"; sleep 1" sh "$ready_file"
  fi
}

trap cleanup EXIT

# 同じGit common directoryを共有する2つのworktreeを作る。
git init -q "$repository"
git -C "$repository" -c user.name=Codex -c user.email=codex@example.invalid commit --allow-empty -m init -q
git -C "$repository" branch secondary
git -C "$repository" worktree add -q "$linked_worktree" secondary
repository_common_dir="$(git -C "$repository" rev-parse --path-format=absolute --git-common-dir)"

# 差分更新、完了、機密field拒否に使うprivate JSONを用意する。
jq -n '{canonical_url:"https://example.invalid/design", body_digest:"sha256:2222222222222222222222222222222222222222222222222222222222222222", context_digest:"sha256:3333333333333333333333333333333333333333333333333333333333333333", message_id:"message-1", approval:{digest:"sha256:4444444444444444444444444444444444444444444444444444444444444444", revision:1}}' >"$value_file"
jq -n '{pending_operation:{id:"op-1"}, approval:{status:"approved"}}' >"$delta_file"
jq -n '{issue_url:"https://example.invalid/issues/1"}' >"$result_file"
jq -n '{payload:{digest:"sha256:5555555555555555555555555555555555555555555555555555555555555555"}}' >"$secret_file"
jq -n '{result:"confidential full issue body"}' >"$invalid_result_file"
jq -n '{body_digest:"not-a-digest"}' >"$invalid_digest_file"
jq -n '{status:1}' >"$invalid_type_file"
jq -n '{canonical_url:"https://example.invalid/design?access_token=confidential"}' >"$invalid_url_file"
chmod 600 "$value_file" "$delta_file" "$result_file" "$secret_file" "$invalid_result_file" "$invalid_digest_file" "$invalid_type_file" "$invalid_url_file"

# 要件本文の代わりにdigestをidentityへ固定してstateを初期化する。
(
  cd "$repository"
  bash "$state_script" init \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" >/dev/null
)

# 別worktreeから同じstateを検証し、最初のnamespace値を保存する。
(
  cd "$linked_worktree"
  bash "$state_script" verify \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" >/dev/null
  bash "$state_script" update \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" \
    --repository-common-dir "$repository_common_dir" \
    --namespace publication \
    --expected-revision 0 \
    --value-file "$value_file" >/dev/null
)

# 同じnamespaceへの差分更新が既存情報を保持したままdeep mergeされることを確かめる。
(
  cd "$repository"
  bash "$state_script" update \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" \
    --repository-common-dir "$repository_common_dir" \
    --namespace publication \
    --expected-revision 1 \
    --value-file "$delta_file" >/dev/null
  test "$(jq -r '.namespaces.publication.canonical_url' .git/agent-workflows/test-design.json)" = 'https://example.invalid/design'
  test "$(jq -r '.namespaces.publication.pending_operation.id' .git/agent-workflows/test-design.json)" = 'op-1'
  test "$(jq -r '.namespaces.publication.approval.digest' .git/agent-workflows/test-design.json)" = 'sha256:4444444444444444444444444444444444444444444444444444444444444444'
  test "$(jq -r '.namespaces.publication.approval.status' .git/agent-workflows/test-design.json)" = 'approved'
)

# 古いrevisionによる上書きを拒否することを確かめる。
if (
  cd "$repository"
  bash "$state_script" update \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" \
    --repository-common-dir "$repository_common_dir" \
    --namespace publication \
    --expected-revision 1 \
    --value-file "$value_file" >/dev/null 2>&1
); then
  printf '%s\n' 'expected stale revision to fail' >&2
  exit 1
fi

# 保存済みidentityと異なるsubjectによる更新を拒否することを確かめる。
if (
  cd "$repository"
  bash "$state_script" update \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$other_subject_digest" \
    --repository-common-dir "$repository_common_dir" \
    --namespace publication \
    --expected-revision 2 \
    --value-file "$value_file" >/dev/null 2>&1
); then
  printf '%s\n' 'expected mismatched identity to fail' >&2
  exit 1
fi

# metadata schema外のcontainer、本文値、digest形式を拒否することを確かめる。
for prohibited_file in "$secret_file" "$invalid_result_file" "$invalid_digest_file" "$invalid_type_file" "$invalid_url_file"; do
  if (
    cd "$repository"
    bash "$state_script" update \
      --workflow-id test-design \
      --workflow workflow-design \
      --subject-kind requirement \
      --subject "$subject_digest" \
      --repository-common-dir "$repository_common_dir" \
      --namespace credentials \
      --expected-revision 2 \
      --value-file "$prohibited_file" >/dev/null 2>&1
  ); then
    printf '%s\n' 'expected invalid state metadata to fail' >&2
    exit 1
  fi
done

# 同じidentityを持つ別repositoryへ、検証済みGit common directoryを取り違えて書けないことを確かめる。
git init -q "$other_repository"
git -C "$other_repository" -c user.name=Codex -c user.email=codex@example.invalid commit --allow-empty -m init -q
(
  cd "$other_repository"
  bash "$state_script" init \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" >/dev/null
)
if (
  cd "$other_repository"
  bash "$state_script" update \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" \
    --repository-common-dir "$repository_common_dir" \
    --namespace publication \
    --expected-revision 0 \
    --value-file "$value_file" >/dev/null 2>&1
); then
  printf '%s\n' 'expected repository identity mismatch to fail' >&2
  exit 1
fi

# requirement identityへ生の要件文字列を保存できないことを確かめる。
if (
  cd "$repository"
  bash "$state_script" init \
    --workflow-id raw-requirement \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject raw-requirement >/dev/null 2>&1
); then
  printf '%s\n' 'expected raw requirement identity to fail' >&2
  exit 1
fi

# 別processが保持するOS levelのlockと並行更新しないことを確かめる。
state_dir="$repository/.git/agent-workflows"
hold_test_lock "$state_dir/test-design.lock" "$lock_ready" &
holder_pid="$!"
for _ in {1..100}; do
  [[ -f "$lock_ready" ]] && break
  sleep 0.01
done
[[ -f "$lock_ready" ]] || { printf '%s\n' 'lock holder did not start' >&2; exit 1; }
if (
  cd "$repository"
  bash "$state_script" verify \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" >/dev/null 2>&1
); then
  printf '%s\n' 'expected concurrent lock acquisition to fail' >&2
  exit 1
fi
wait "$holder_pid"
holder_pid=""

# Process終了後は残ったlock fileをstale扱いせず、OSから同じlockを再取得する。
(
  cd "$repository"
  bash "$state_script" verify \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" >/dev/null
)

# 完全なidentityと最新revisionでstateを完了し、監査情報を確かめる。
(
  cd "$repository"
  bash "$state_script" complete \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" \
    --repository-common-dir "$repository_common_dir" \
    --expected-revision 2 \
    --result-file "$result_file" >/dev/null
  test "$(jq -r '.status' .git/agent-workflows/test-design.json)" = 'completed'
  test "$(jq -r '.revision' .git/agent-workflows/test-design.json)" = '3'
)

printf '%s\n' 'workflow-state tests passed'
