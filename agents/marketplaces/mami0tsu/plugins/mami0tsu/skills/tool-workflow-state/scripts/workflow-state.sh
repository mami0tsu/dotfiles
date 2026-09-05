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
    [[ ! "$subject" =~ [[:space:]?\&=@] ]] || die "subject must be an identifier or canonical URL without a query or userinfo"
    [[ "$subject" =~ ^https://[^[:space:]?\&=@]+$ || "$subject" =~ ^[A-Za-z0-9][A-Za-z0-9._:/#-]{0,511}$ ]] || die "invalid subject"
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
  if ! printf '%s\n' "$validated_json" | jq -e '
    def normalized_key:
      ascii_downcase | gsub("[^a-z0-9]+"; "_");
    def prohibited_key:
      normalized_key | test("(^|_)(token|password|secret|credential|apikey|authorization|authheader)(_|$)");
    def scalar_key:
      normalized_key
      | test("^(id|ids|url|urls|uri|uris|revision|revisions|digest|digests|status|statuses|state|states|kind|kinds|provider|providers|container|containers|type|types|operation|operations|action|actions|completed|verified|marker|markers|timestamp|timestamps|at|path|paths|directory|directories|dir|dirs|repository|repositories|branch|branches|commit|commits|oid|oids|number|numbers|key|keys|relation|relations)$|_(id|ids|url|urls|uri|uris|revision|revisions|digest|digests|status|statuses|state|states|kind|kinds|provider|providers|container|containers|type|types|operation|operations|action|actions|completed|verified|marker|markers|timestamp|timestamps|at|path|paths|directory|directories|dir|dirs|repository|repositories|branch|branches|commit|commits|oid|oids|number|numbers|key|keys|relation|relations)$");
    def container_key:
      normalized_key
      | test("^(approval|approvals|pending_operation|pending_operations|completed_operation|completed_operations|external_object|external_objects|object|objects|issue|issues|document|documents|pull_request|pull_requests|artifact|artifacts|verification|verifications|relation|relations|target|targets|source|sources|result|results|canonical|tracking|design|implementation|publication|repository|repositories|branch|branches|before|after|expected|actual)$");
    def safe_token:
      type == "string" and length > 0 and length <= 256 and test("^[A-Za-z0-9][A-Za-z0-9._:/#@+-]*$");
    def valid_scalar($raw_key; $value):
      ($raw_key | normalized_key) as $key
      | if $raw_key | prohibited_key then
          false
        elif $value == null then
          (($raw_key | scalar_key) or ($raw_key | container_key))
        elif $key | test("(^|_)(digest|digests)$") then
          ($value | type == "string" and test("^sha256:[a-f0-9]{64}$"))
        elif $key | test("(^|_)(url|urls|uri|uris)$") then
          ($value | type == "string" and length <= 2048 and test("^https://[^[:space:]?&=@]+$"))
        elif $key | test("(^|_)(revision|revisions)$") then
          (($value | type == "number" and . >= 0 and floor == .) or ($value | safe_token))
        elif $key | test("(^|_)(number|numbers)$") then
          ($value | type == "number" and . >= 0 and floor == .)
        elif $key | test("(^|_)(completed|verified)$") then
          ($value | type == "boolean")
        elif $key | test("(^|_)(timestamp|timestamps|at)$") then
          ($value | type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"))
        elif $key | test("(^|_)(commit|commits|oid|oids)$") then
          ($value | type == "string" and test("^[a-f0-9]{7,64}$"))
        elif $key | test("(^|_)(path|paths|directory|directories|dir|dirs)$") then
          ($value | type == "string" and length > 0 and length <= 1024 and test("^[^[:cntrl:]]+$"))
        elif $key | test("(^|_)(repository|repositories)$") then
          ($value | (safe_token or (type == "string" and length <= 2048 and test("^https://[^[:space:]?&=@]+$"))))
        elif $raw_key | scalar_key then
          ($value | safe_token)
        else
          false
        end;
    def valid_value($parent_key):
      if type == "object" then
        all(to_entries[];
          .key as $key
          | .value
          | if type == "object" then
              (($key | container_key) and valid_value($key))
            elif type == "array" then
              ((($key | container_key) or ($key | scalar_key)) and valid_value($key))
            else
              valid_scalar($key; .)
            end)
      elif type == "array" then
        all(.[];
          if type == "object" or type == "array" then
            valid_value($parent_key)
          else
            valid_scalar($parent_key; .)
          end)
      else
        valid_scalar($parent_key; .)
      end;
    valid_value("")
  ' >/dev/null; then
    die "JSON does not match the state metadata schema"
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

# OSがprocess終了時に解放するfile lockで、Workflow単位の更新を直列化する。
acquire_lock() {
  mkdir -p "$state_dir"
  chmod 700 "$state_dir"
  exec 9>"$lock_path"
  chmod 600 "$lock_path"
  if command -v lockf >/dev/null 2>&1; then
    lockf -s -t 0 9 || die "state is locked: $workflow_id"
  elif command -v flock >/dev/null 2>&1; then
    flock -n 9 || die "state is locked: $workflow_id"
  else
    die "lockf or flock is required"
  fi
}

# 現在processが保持するfile descriptorを閉じてlockを解放する。
release_lock() {
  exec 9>&-
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
  acquire_lock
  trap release_lock EXIT
  [[ ! -e "$state_file" ]] || die "state already exists: $workflow_id"
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
  require_command git
  require_command jq
  require_command stat
  umask 077
  local command_name="${1:-}"
  [[ -n "$command_name" ]] || die "command is required"
  shift
  case "$command_name" in
    init) initialize_state "$@" ;;
    verify) verify_state "$@" ;;
    update) update_state "$@" ;;
    complete) complete_state "$@" ;;
    *) die "unknown command: $command_name" ;;
  esac
}

main "$@"
