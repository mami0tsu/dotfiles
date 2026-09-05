#!/usr/bin/env bash

set -euo pipefail

# 一時repositoryと検証用JSONの配置先を準備する。
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
state_script="$script_dir/workflow-state.sh"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/workflow-state-test.XXXXXX")"
repository="$test_root/repository"
linked_worktree="$test_root/linked"
other_repository="$test_root/other-repository"
concurrent_repository="$test_root/concurrent-repository"
generated_repository="$test_root/generated-repository"
symlink_repository="$test_root/symlink-repository"
symlink_directory_repository="$test_root/symlink-directory-repository"
value_file="$test_root/value.json"
delta_file="$test_root/delta.json"
result_file="$test_root/result.json"
secret_file="$test_root/secret.json"
invalid_result_file="$test_root/invalid-result.json"
invalid_digest_file="$test_root/invalid-digest.json"
invalid_type_file="$test_root/invalid-type.json"
invalid_url_file="$test_root/invalid-url.json"
credential_alias_file="$test_root/credential-alias.json"
api_alias_file="$test_root/api-alias.json"
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
jq -n '{credential_id:"top-secret-token", access_token_id:"ghp_secret", password_digest:"sha256:6666666666666666666666666666666666666666666666666666666666666666"}' >"$credential_alias_file"
jq -n '{api_key:"ghp_secret", "api-key":"ghp_secret", auth_header:"Bearer-secret"}' >"$api_alias_file"
chmod 600 "$value_file" "$delta_file" "$result_file" "$secret_file" "$invalid_result_file" "$invalid_digest_file" "$invalid_type_file" "$invalid_url_file" "$credential_alias_file" "$api_alias_file"

# 要件本文の代わりにdigestをidentityへ固定してstateを初期化する。
(
  cd "$repository"
  bash "$state_script" init \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" >/dev/null
)

# Workflow IDを省略した新規作業では、安全なIDが生成されて結果にも含まれることを確かめる。
git init -q "$generated_repository"
git -C "$generated_repository" -c user.name=Codex -c user.email=codex@example.invalid commit --allow-empty -m init -q
generated_result="$test_root/generated-result.json"
(
  cd "$generated_repository"
  bash "$state_script" init \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" >"$generated_result"
)
generated_workflow_id="$(jq -r '.workflow_id' "$generated_result")"
[[ "$generated_workflow_id" =~ ^workflow-design-[0-9]{8}T[0-9]{6}Z-[0-9]+-[0-9]+$ ]]
test -f "$generated_repository/.git/agent-workflows/$generated_workflow_id.json"

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
    --value-file "$value_file" >"$test_root/update-result.json"
)
test "$(jq -r '.identity.repository_common_dir' "$test_root/update-result.json")" = "$repository_common_dir"
test "$(jq -r '.revision' "$test_root/update-result.json")" = '1'

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

# State置換に失敗しても一時fileを残さず、既存stateを変更しないことを確かめる。
fake_bin="$test_root/fake-bin"
mkdir -m 700 "$fake_bin"
printf '%s\n' '#!/usr/bin/env sh' 'exit 7' >"$fake_bin/mv"
chmod 700 "$fake_bin/mv"
if (
  cd "$repository"
  PATH="$fake_bin:$PATH" bash "$state_script" update \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" \
    --repository-common-dir "$repository_common_dir" \
    --namespace publication \
    --expected-revision 2 \
    --value-file "$value_file" >/dev/null 2>&1
); then
  printf '%s\n' 'expected state replacement failure' >&2
  exit 1
fi
test "$(jq -r '.revision' "$repository/.git/agent-workflows/test-design.json")" = '2'
test -z "$(find "$repository/.git/agent-workflows" -maxdepth 1 -name '.workflow-*' -print -quit)"

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
for prohibited_file in "$secret_file" "$invalid_result_file" "$invalid_digest_file" "$invalid_type_file" "$invalid_url_file" "$credential_alias_file" "$api_alias_file"; do
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

# state directoryとlock pathのsymbolic linkを拒否し、参照先を変更しないことを確かめる。
git init -q "$symlink_repository"
git -C "$symlink_repository" -c user.name=Codex -c user.email=codex@example.invalid commit --allow-empty -m init -q
mkdir -m 700 "$symlink_repository/.git/agent-workflows"
printf '%s\n' 'victim-content' >"$test_root/lock-victim"
ln -s "$test_root/lock-victim" "$symlink_repository/.git/agent-workflows/symlink-design.lock"
if (
  cd "$symlink_repository"
  bash "$state_script" init \
    --workflow-id symlink-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" >/dev/null 2>&1
); then
  printf '%s\n' 'expected symbolic link lock to fail' >&2
  exit 1
fi
test "$(command cat "$test_root/lock-victim")" = 'victim-content'

# Git common directory外を指すstate directoryのsymbolic linkを拒否することを確かめる。
git init -q "$symlink_directory_repository"
git -C "$symlink_directory_repository" -c user.name=Codex -c user.email=codex@example.invalid commit --allow-empty -m init -q
mkdir -m 700 "$test_root/outside-state-directory"
ln -s "$test_root/outside-state-directory" "$symlink_directory_repository/.git/agent-workflows"
if (
  cd "$symlink_directory_repository"
  bash "$state_script" init \
    --workflow-id symlink-directory-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" >/dev/null 2>&1
); then
  printf '%s\n' 'expected symbolic link state directory to fail' >&2
  exit 1
fi
test -z "$(find "$test_root/outside-state-directory" -mindepth 1 -print -quit)"

# 複数processが同じWorkflow IDを同時初期化しても、1件だけが成功することを確かめる。
git init -q "$concurrent_repository"
git -C "$concurrent_repository" -c user.name=Codex -c user.email=codex@example.invalid commit --allow-empty -m init -q
concurrent_pids=()
for attempt in {1..32}; do
  (
    cd "$concurrent_repository"
    bash "$state_script" init \
      --workflow-id concurrent-design \
      --workflow workflow-design \
      --subject-kind requirement \
      --subject "$subject_digest" >"$test_root/concurrent-$attempt.out" 2>"$test_root/concurrent-$attempt.err" &&
      touch "$test_root/concurrent-$attempt.succeeded"
  ) &
  concurrent_pids+=("$!")
done
for concurrent_pid in "${concurrent_pids[@]}"; do
  wait "$concurrent_pid" || true
done
success_count=0
for attempt in {1..32}; do
  if [[ -f "$test_root/concurrent-$attempt.succeeded" ]]; then
    ((success_count += 1))
  fi
done
test "$success_count" = '1'
test "$(jq -r '.revision' "$concurrent_repository/.git/agent-workflows/concurrent-design.json")" = '0'

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
