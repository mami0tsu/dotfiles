#!/usr/bin/env bash

set -euo pipefail

# 共通の入力検査とエラー処理をまとめる。

# 呼び出し元へ一定形式のエラーを返して終了する。
die() {
  printf '%s\n' "error: $*" >&2
  exit 1
}

# 実行に必要なcommandがPATH上にあることを確認する。
require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

# optionの直後に空でない値があることを確認する。
require_value() {
  local option="$1"
  local value="${2:-}"
  [[ -n "$value" ]] || die "missing value for $option"
}

# file名へ使うWorkflow IDを安全な文字と長さへ制限する。
validate_workflow_id() {
  [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]] || die "invalid workflow id"
}

# namespaceをJSON objectのkeyとして扱える文字へ制限する。
validate_namespace() {
  [[ "$1" =~ ^[a-z0-9][a-z0-9-]{0,63}$ ]] || die "invalid namespace"
}

# identityへ本文やcredentialが混入しない形式を強制する。
validate_identity() {
  validate_workflow_id "$workflow_id"
  [[ "$workflow" =~ ^[a-z0-9][a-z0-9-]{0,63}$ ]] || die "invalid workflow name"
  [[ "$subject_kind" =~ ^(issue|document|pull-request|ticket|pr|requirement)$ ]] || die "invalid subject kind"
  if [[ "$subject_kind" == "requirement" ]]; then
    [[ "$subject" =~ ^sha256:[a-f0-9]{64}$ ]] || die "requirement subject must be a sha256 digest"
  else
    ((${#subject} <= 2048)) || die "subject is too long"
    [[ ! "$subject" =~ [[:space:]?\&=] ]] || die "subject must be an identifier or canonical URL without a query"
    [[ "$subject" =~ ^https://[^[:space:]?\&=]+$ || "$subject" =~ ^[A-Za-z0-9][A-Za-z0-9._:/#-]{0,511}$ ]] || die "invalid subject"
  fi
}

# private JSONを1回だけ読み、型、所有者、権限、scalarを持つkeyのallowlistを検査する。
validate_private_json_object() {
  local file="$1"
  [[ -f "$file" && -r "$file" ]] || die "JSON file must be a readable regular file: $file"
  local owner_id permission_mode
  if stat -f '%u' "$file" >/dev/null 2>&1; then
    owner_id="$(stat -f '%u' "$file")"
    permission_mode="$(stat -f '%Lp' "$file")"
  else
    owner_id="$(stat -c '%u' "$file")"
    permission_mode="$(stat -c '%a' "$file")"
  fi
  [[ "$owner_id" == "$(id -u)" ]] || die "JSON file must be owned by the current user"
  (( (8#$permission_mode & 077) == 0 )) || die "JSON file must not be accessible by group or other users"
  validated_json="$(jq -ce 'if type == "object" then . else error("JSON value must be an object") end' "$file")" || die "JSON value must be an object"
  if printf '%s\n' "$validated_json" | jq -e '
    def normalized_key:
      ascii_downcase | gsub("[^a-z0-9]+"; "_");
    def allowed_metadata_key:
      test("^(id|ids|url|urls|uri|uris|revision|revisions|digest|digests|status|statuses|state|states|kind|kinds|provider|providers|container|containers|type|types|operation|operations|action|actions|result|results|completed|verified|marker|markers|timestamp|timestamps|at|path|paths|directory|directories|dir|dirs|repository|repositories|branch|branches|commit|commits|oid|oids|number|numbers|key|keys|relation|relations)$|_(id|ids|url|urls|uri|uris|revision|revisions|digest|digests|status|statuses|state|states|kind|kinds|provider|providers|container|containers|type|types|operation|operations|action|actions|result|results|completed|verified|marker|markers|timestamp|timestamps|at|path|paths|directory|directories|dir|dirs|repository|repositories|branch|branches|commit|commits|oid|oids|number|numbers|key|keys|relation|relations)$");
    [paths(scalars) as $path
      | ($path | map(select(type == "string")) | last // "" | normalized_key)
      | select(allowed_metadata_key | not)]
    | length > 0
  ' >/dev/null; then
    die "JSON contains a field outside the state metadata allowlist"
  fi
}

# worktree間で共通する保存先と、初期identityに使うGit情報を取得する。

# 現在位置からGit common directory、branch、開始commitを解決する。
resolve_repository() {
  git rev-parse --show-toplevel >/dev/null 2>&1 || die "not inside a Git repository"
  common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || die "cannot resolve Git common directory"
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || printf '%s' 'DETACHED')"
  start_commit="$(git rev-parse HEAD 2>/dev/null)" || die "cannot resolve HEAD"
  state_dir="$common_dir/agent-workflows"
}

# 検査済みWorkflow IDからstate fileとlock pathを組み立てる。
state_path_for() {
  state_file="$state_dir/$workflow_id.json"
  lock_path="$state_dir/$workflow_id.lock"
}

# process所有者tokenを使って並行更新を直列化し、終了済み所有者のlockを回復する。

# Hostname変更の影響を受けないmachine IDを取得する。
read_machine_id() {
  local value=""
  if [[ -r /etc/machine-id ]]; then
    value="$(tr -d '[:space:]' </etc/machine-id)"
  elif [[ "$(uname -s)" == "Darwin" && -x /usr/sbin/ioreg ]]; then
    value="$(/usr/sbin/ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $(NF-1); exit}')"
  fi
  [[ "$value" =~ ^[A-Za-z0-9._-]+$ ]] || die "cannot resolve a stable machine id"
  printf '%s' "$value"
}

# 再起動前のlockを区別するboot session IDを取得する。
read_boot_id() {
  local value=""
  if [[ -r /proc/sys/kernel/random/boot_id ]]; then
    value="$(tr -d '[:space:]' </proc/sys/kernel/random/boot_id)"
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    value="$(sysctl -n kern.bootsessionuuid 2>/dev/null || true)"
  fi
  [[ "$value" =~ ^[A-Za-z0-9._-]+$ ]] || die "cannot resolve a boot session id"
  printf '%s' "$value"
}

# PID再利用を区別するため、process開始時刻をSHA-256へ変換する。
read_process_start_id() {
  local process_id="$1" start_value digest_line
  start_value="$(ps -o lstart= -p "$process_id" 2>/dev/null)" || return 1
  [[ -n "${start_value//[[:space:]]/}" ]] || return 1
  digest_line="$(printf '%s' "$start_value" | shasum -a 256)"
  printf '%s' "${digest_line%% *}"
}

# 現在processを一意に表すowner tokenを組み立てる。
build_lock_token() {
  local process_start_id
  process_start_id="$(read_process_start_id "$$")" || die "cannot resolve current process start time"
  lock_token="$(read_machine_id):$(read_boot_id):$$:$process_start_id:$(date '+%s'):$RANDOM"
}

# atomicなsymlinkにあるowner tokenを検査し、終了済み所有者のlockだけを移動して回収する。
recover_stale_lock() {
  local owner_token owner_machine owner_boot owner_pid owner_start owner_created owner_nonce owner_extra
  local current_machine current_boot current_start="" stale_lock
  owner_token="$(readlink "$lock_path" 2>/dev/null)" || return 1
  IFS=: read -r owner_machine owner_boot owner_pid owner_start owner_created owner_nonce owner_extra <<<"$owner_token"
  [[ -z "$owner_extra" && "$owner_machine" =~ ^[A-Za-z0-9._-]+$ && "$owner_boot" =~ ^[A-Za-z0-9._-]+$ ]] || return 1
  [[ "$owner_pid" =~ ^[0-9]+$ && "$owner_start" =~ ^[a-f0-9]{64}$ && "$owner_created" =~ ^[0-9]+$ && "$owner_nonce" =~ ^[0-9]+$ ]] || return 1
  current_machine="$(read_machine_id)"
  current_boot="$(read_boot_id)"
  [[ "$owner_machine" == "$current_machine" ]] || return 1
  if [[ "$owner_boot" == "$current_boot" ]]; then
    current_start="$(read_process_start_id "$owner_pid" || true)"
    [[ -z "$current_start" || "$current_start" != "$owner_start" ]] || return 1
  fi
  stale_lock="$state_dir/.$workflow_id.stale-lock.$$.$RANDOM"
  mv "$lock_path" "$stale_lock" 2>/dev/null || return 1
  [[ "$(readlink "$stale_lock" 2>/dev/null || true)" == "$owner_token" ]] || die "stale lock token changed during recovery"
  rm -f "$stale_lock"
}

# Workflow単位のlockをatomicに取得する。
acquire_lock() {
  mkdir -p "$state_dir"
  chmod 700 "$state_dir"
  build_lock_token
  if ! ln -s "$lock_token" "$lock_path" 2>/dev/null; then
    if ! recover_stale_lock; then
      die "state is locked: $workflow_id (owner token: $(readlink "$lock_path" 2>/dev/null || printf '%s' unknown))"
    fi
    ln -s "$lock_token" "$lock_path" 2>/dev/null || die "state is locked: $workflow_id"
  fi
}

# owner tokenが一致する自processのlockだけを解放する。
release_lock() {
  if [[ -L "${lock_path:-}" && "$(readlink "$lock_path" 2>/dev/null || true)" == "${lock_token:-}" ]]; then
    rm -f "$lock_path"
  fi
}

# 人間がstaleと確認したforeign lockを、提示済みowner tokenとの一致を条件に回収する。
repair_state_lock() {
  local expected_owner_token="" confirmed=""
  workflow_id=""
  while (($#)); do
    case "$1" in
      --workflow-id) require_value "$1" "${2:-}"; workflow_id="$2"; shift 2 ;;
      --expected-owner-token) require_value "$1" "${2:-}"; expected_owner_token="$2"; shift 2 ;;
      --confirmed-stale) confirmed="yes"; shift ;;
      *) die "unknown option: $1" ;;
    esac
  done
  [[ -n "$workflow_id" && -n "$expected_owner_token" && "$confirmed" == "yes" ]] || die "repair options and explicit stale confirmation are required"
  validate_workflow_id "$workflow_id"
  resolve_repository
  state_path_for
  [[ -L "$lock_path" ]] || die "state lock not found: $workflow_id"
  [[ "$(readlink "$lock_path")" == "$expected_owner_token" ]] || die "state lock owner token does not match"
  local repaired_lock="$state_dir/.$workflow_id.repaired-lock.$$.$RANDOM"
  mv "$lock_path" "$repaired_lock" 2>/dev/null || die "state lock changed before repair"
  [[ "$(readlink "$repaired_lock" 2>/dev/null || true)" == "$expected_owner_token" ]] || die "state lock owner token changed during repair"
  rm -f "$repaired_lock"
  jq -n --arg workflow_id "$workflow_id" --arg owner_token "$expected_owner_token" '{workflow_id: $workflow_id, repaired: true, owner_token: $owner_token}'
}

# 同じdirectoryの一時fileへ完全なJSONを書き、renameで原子的に置き換える。
write_state() {
  local source_file="$1"
  local temporary_file
  temporary_file="$(mktemp "$state_dir/.workflow-state.XXXXXX")"
  chmod 600 "$temporary_file"
  jq '.' "$source_file" >"$temporary_file"
  mv "$temporary_file" "$state_file"
  chmod 600 "$state_file"
}

# stateの最低限のschemaと進行状態を検査する。
read_state() {
  [[ -f "$state_file" ]] || die "state not found: $workflow_id"
  jq -e '
    type == "object"
    and .schema_version == 1
    and (.identity | type == "object")
    and (.namespaces | type == "object")
    and (.revision | type == "number")
    and (.status == "active" or .status == "completed")
  ' "$state_file" >/dev/null || die "state is invalid: $workflow_id"
}

# 保存済みidentityを現在のGit common directoryと呼び出し入力へ結び付ける。
verify_stored_identity() {
  jq -e \
    --arg workflow_id "$workflow_id" \
    --arg workflow "$workflow" \
    --arg subject_kind "$subject_kind" \
    --arg subject "$subject" \
    --arg repository_common_dir "$common_dir" \
    '.workflow_id == $workflow_id and .identity.workflow == $workflow and .identity.subject_kind == $subject_kind and .identity.subject == $subject and .identity.repository_common_dir == $repository_common_dir' \
    "$state_file" >/dev/null || die "state identity does not match"
}

# 初期化と検証に共通するidentity optionを読み取る。
parse_identity_options() {
  workflow_id=""
  workflow=""
  subject_kind=""
  subject=""
  while (($#)); do
    case "$1" in
      --workflow-id) require_value "$1" "${2:-}"; workflow_id="$2"; shift 2 ;;
      --workflow) require_value "$1" "${2:-}"; workflow="$2"; shift 2 ;;
      --subject-kind) require_value "$1" "${2:-}"; subject_kind="$2"; shift 2 ;;
      --subject) require_value "$1" "${2:-}"; subject="$2"; shift 2 ;;
      *) die "unknown option: $1" ;;
    esac
  done
  [[ -n "$workflow_id" && -n "$workflow" && -n "$subject_kind" && -n "$subject" ]] || die "identity options are required"
  validate_identity
}

# lifecycle commandごとの処理を実装する。

# 新しいactive stateを作り、Gitとsubjectのidentityを固定する。
initialize_state() {
  parse_identity_options "$@"
  resolve_repository
  state_path_for
  [[ ! -e "$state_file" ]] || die "state already exists: $workflow_id"
  acquire_lock
  trap release_lock EXIT
  local now draft
  now="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  draft="$(mktemp)"
  jq -n \
    --arg workflow_id "$workflow_id" \
    --arg workflow "$workflow" \
    --arg subject_kind "$subject_kind" \
    --arg subject "$subject" \
    --arg repository_common_dir "$common_dir" \
    --arg branch "$branch" \
    --arg start_commit "$start_commit" \
    --arg now "$now" \
    '{schema_version: 1, workflow_id: $workflow_id, identity: {workflow: $workflow, subject_kind: $subject_kind, subject: $subject, repository_common_dir: $repository_common_dir, branch: $branch, start_commit: $start_commit}, status: "active", revision: 0, namespaces: {}, created_at: $now, updated_at: $now, completed_at: null, result: null}' >"$draft"
  write_state "$draft"
  rm -f "$draft"
  jq --arg path "$state_file" '{state_path: $path, identity: .identity, status, revision}' "$state_file"
}

# lock下でstateを読み、identityが一致する場合だけ内容を返す。
verify_state() {
  parse_identity_options "$@"
  resolve_repository
  state_path_for
  acquire_lock
  trap release_lock EXIT
  read_state
  verify_stored_identity
  jq '.' "$state_file"
}

# 1つのnamespaceへ差分をdeep mergeし、revisionを1つ進める。
update_state() {
  local namespace="" expected_revision="" value_file="" expected_common_dir=""
  workflow_id=""
  workflow=""
  subject_kind=""
  subject=""
  while (($#)); do
    case "$1" in
      --workflow-id) require_value "$1" "${2:-}"; workflow_id="$2"; shift 2 ;;
      --workflow) require_value "$1" "${2:-}"; workflow="$2"; shift 2 ;;
      --subject-kind) require_value "$1" "${2:-}"; subject_kind="$2"; shift 2 ;;
      --subject) require_value "$1" "${2:-}"; subject="$2"; shift 2 ;;
      --repository-common-dir) require_value "$1" "${2:-}"; expected_common_dir="$2"; shift 2 ;;
      --namespace) require_value "$1" "${2:-}"; namespace="$2"; shift 2 ;;
      --expected-revision) require_value "$1" "${2:-}"; expected_revision="$2"; shift 2 ;;
      --value-file) require_value "$1" "${2:-}"; value_file="$2"; shift 2 ;;
      *) die "unknown option: $1" ;;
    esac
  done
  [[ -n "$workflow_id" && -n "$workflow" && -n "$subject_kind" && -n "$subject" && -n "$expected_common_dir" && -n "$namespace" && -n "$expected_revision" && -n "$value_file" ]] || die "update options are required"
  validate_identity
  validate_namespace "$namespace"
  [[ "$expected_revision" =~ ^[0-9]+$ ]] || die "expected revision must be a non-negative integer"
  validate_private_json_object "$value_file"
  resolve_repository
  [[ "$common_dir" == "$expected_common_dir" ]] || die "repository common directory does not match verified state"
  state_path_for
  acquire_lock
  trap release_lock EXIT
  read_state
  verify_stored_identity
  [[ "$(jq -r '.status' "$state_file")" == "active" ]] || die "state is not active"
  [[ "$(jq -r '.revision' "$state_file")" == "$expected_revision" ]] || die "state revision does not match"
  jq -e --arg namespace "$namespace" '(.namespaces[$namespace] // {}) | type == "object"' "$state_file" >/dev/null || die "namespace is not an object"
  local now draft
  now="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  draft="$(mktemp)"
  jq \
    --arg namespace "$namespace" \
    --arg now "$now" \
    --argjson value "$validated_json" \
    '.namespaces[$namespace] = ((.namespaces[$namespace] // {}) * $value) | .revision += 1 | .updated_at = $now' \
    "$state_file" >"$draft"
  write_state "$draft"
  rm -f "$draft"
  jq --arg namespace "$namespace" '{workflow_id, status, revision, namespace: $namespace, value: .namespaces[$namespace]}' "$state_file"
}

# 完全なidentityとrevisionを照合し、監査用の完了結果を残す。
complete_state() {
  local expected_revision="" result_file="" expected_common_dir=""
  workflow_id=""
  workflow=""
  subject_kind=""
  subject=""
  while (($#)); do
    case "$1" in
      --workflow-id) require_value "$1" "${2:-}"; workflow_id="$2"; shift 2 ;;
      --workflow) require_value "$1" "${2:-}"; workflow="$2"; shift 2 ;;
      --subject-kind) require_value "$1" "${2:-}"; subject_kind="$2"; shift 2 ;;
      --subject) require_value "$1" "${2:-}"; subject="$2"; shift 2 ;;
      --repository-common-dir) require_value "$1" "${2:-}"; expected_common_dir="$2"; shift 2 ;;
      --expected-revision) require_value "$1" "${2:-}"; expected_revision="$2"; shift 2 ;;
      --result-file) require_value "$1" "${2:-}"; result_file="$2"; shift 2 ;;
      *) die "unknown option: $1" ;;
    esac
  done
  [[ -n "$workflow_id" && -n "$workflow" && -n "$subject_kind" && -n "$subject" && -n "$expected_common_dir" && -n "$expected_revision" && -n "$result_file" ]] || die "complete options are required"
  validate_identity
  [[ "$expected_revision" =~ ^[0-9]+$ ]] || die "expected revision must be a non-negative integer"
  validate_private_json_object "$result_file"
  resolve_repository
  [[ "$common_dir" == "$expected_common_dir" ]] || die "repository common directory does not match verified state"
  state_path_for
  acquire_lock
  trap release_lock EXIT
  read_state
  verify_stored_identity
  [[ "$(jq -r '.status' "$state_file")" == "active" ]] || die "state is not active"
  [[ "$(jq -r '.revision' "$state_file")" == "$expected_revision" ]] || die "state revision does not match"
  local now draft
  now="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  draft="$(mktemp)"
  jq \
    --arg now "$now" \
    --argjson result "$validated_json" \
    '.status = "completed" | .revision += 1 | .updated_at = $now | .completed_at = $now | .result = $result' \
    "$state_file" >"$draft"
  write_state "$draft"
  rm -f "$draft"
  jq '{workflow_id, status, revision, completed_at, result}' "$state_file"
}

# 依存commandを確認して、指定されたlifecycle commandだけを実行する。
main() {
  require_command awk
  require_command git
  require_command jq
  require_command ln
  require_command ps
  require_command readlink
  require_command shasum
  require_command stat
  require_command tr
  require_command uname
  umask 077
  local command_name="${1:-}"
  [[ -n "$command_name" ]] || die "command is required"
  shift
  case "$command_name" in
    init) initialize_state "$@" ;;
    verify) verify_state "$@" ;;
    update) update_state "$@" ;;
    complete) complete_state "$@" ;;
    repair-lock) repair_state_lock "$@" ;;
    *) die "unknown command: $command_name" ;;
  esac
}

main "$@"
