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
subject_digest="sha256:0000000000000000000000000000000000000000000000000000000000000000"
other_subject_digest="sha256:1111111111111111111111111111111111111111111111111111111111111111"

# 試験中に作成した限定的な一時directoryだけを削除する。
cleanup() {
  if [[ -n "${test_root:-}" && -d "$test_root" && "$test_root" == "${TMPDIR:-/tmp}/workflow-state-test."* ]]; then
    rm -rf "$test_root"
  fi
}

# 自動回収試験用に、実装と同じ優先順でmachine IDを取得する。
read_test_machine_id() {
  if [[ -r /etc/machine-id ]]; then
    tr -d '[:space:]' </etc/machine-id
  else
    /usr/sbin/ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $(NF-1); exit}'
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
jq -n '{canonical_url:"https://example.invalid/design", body_digest:"sha256:test", context_digest:"sha256:context", message_id:"message-1", approval:{digest:"sha256:approval", revision:1}}' >"$value_file"
jq -n '{pending_operation:{id:"op-1"}, approval:{status:"approved"}}' >"$delta_file"
jq -n '{issue_url:"https://example.invalid/issues/1"}' >"$result_file"
jq -n '{payload:"confidential full issue body"}' >"$secret_file"
chmod 600 "$value_file" "$delta_file" "$result_file" "$secret_file"

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
  test "$(jq -r '.namespaces.publication.approval.digest' .git/agent-workflows/test-design.json)" = 'sha256:approval'
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

# metadata allowlist外のscalar fieldへ本文を保存できないことを確かめる。
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
    --value-file "$secret_file" >/dev/null 2>&1
); then
  printf '%s\n' 'expected prohibited field to fail' >&2
  exit 1
fi

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

# 同じmachineの以前のboot sessionが残したowner tokenを自動回収できることを確かめる。
state_dir="$repository/.git/agent-workflows"
machine_id="$(read_test_machine_id)"
stale_token="$machine_id:previous-boot:2147483647:0000000000000000000000000000000000000000000000000000000000000000:1:1"
ln -s "$stale_token" "$state_dir/test-design.lock"
(
  cd "$repository"
  bash "$state_script" verify \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" >/dev/null
)

# 別machine由来のlockは自動回収せず、人間確認済みの完全なowner tokenでだけ回収する。
foreign_token="foreign-machine:foreign-boot:1:1111111111111111111111111111111111111111111111111111111111111111:1:1"
ln -s "$foreign_token" "$state_dir/test-design.lock"
if (
  cd "$repository"
  bash "$state_script" verify \
    --workflow-id test-design \
    --workflow workflow-design \
    --subject-kind requirement \
    --subject "$subject_digest" >/dev/null 2>&1
); then
  printf '%s\n' 'expected foreign lock to require manual repair' >&2
  exit 1
fi
(
  cd "$repository"
  bash "$state_script" repair-lock \
    --workflow-id test-design \
    --expected-owner-token "$foreign_token" \
    --confirmed-stale >/dev/null
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
