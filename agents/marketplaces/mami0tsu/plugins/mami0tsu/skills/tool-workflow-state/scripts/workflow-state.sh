#!/usr/bin/env bash

set -euo pipefail

die() {
  printf '%s\n' "error: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

require_value() {
  local option="$1"
  local value="${2:-}"
  [[ -n "$value" ]] || die "missing value for $option"
}

validate_workflow_id() {
  [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]] || die "workflow id must match [A-Za-z0-9._-]+"
}

validate_namespace() {
  [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]] || die "namespace must match [A-Za-z0-9._-]+"
}

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
  if jq -en --argjson value "$validated_json" '
    $value
    | [paths(scalars) as $path
      | ($path[-1] | tostring | ascii_downcase)
      | select(test("(^|_)(token|password|secret|credential|apikey|api_key|authorization|authheader|auth_header|body|content|description|comment|message|review|text)(_|$)"))]
    | length > 0
  ' >/dev/null; then
    die "JSON contains a prohibited field name"
  fi
}

resolve_repository() {
  git rev-parse --show-toplevel >/dev/null 2>&1 || die "not inside a Git repository"
  common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || die "cannot resolve Git common directory"
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || printf '%s' 'DETACHED')"
  start_commit="$(git rev-parse HEAD 2>/dev/null)" || die "cannot resolve HEAD"
  state_dir="$common_dir/agent-workflows"
}

state_path_for() {
  state_file="$state_dir/$workflow_id.json"
  lock_dir="$state_dir/$workflow_id.lock"
}

acquire_lock() {
  mkdir -p "$state_dir"
  chmod 700 "$state_dir"
  mkdir "$lock_dir" 2>/dev/null || die "state is locked: $workflow_id"
}

release_lock() {
  if [[ -n "${lock_dir:-}" && -d "$lock_dir" ]]; then
    rmdir "$lock_dir"
  fi
}

write_state() {
  local source_file="$1"
  local temporary_file
  temporary_file="$(mktemp "$state_dir/.workflow-state.XXXXXX")"
  chmod 600 "$temporary_file"
  jq '.' "$source_file" >"$temporary_file"
  mv "$temporary_file" "$state_file"
  chmod 600 "$state_file"
}

read_state() {
  [[ -f "$state_file" ]] || die "state not found: $workflow_id"
  jq -e 'type == "object" and .schema_version == 1' "$state_file" >/dev/null || die "state is invalid: $workflow_id"
}

parse_identity_options() {
  while (($#)); do
    case "$1" in
      --workflow-id) require_value "$1" "${2:-}"; workflow_id="$2"; shift 2 ;;
      --workflow) require_value "$1" "${2:-}"; workflow="$2"; shift 2 ;;
      --subject-kind) require_value "$1" "${2:-}"; subject_kind="$2"; shift 2 ;;
      --subject) require_value "$1" "${2:-}"; subject="$2"; shift 2 ;;
      *) die "unknown option: $1" ;;
    esac
  done
  [[ -n "${workflow_id:-}" && -n "${workflow:-}" && -n "${subject_kind:-}" && -n "${subject:-}" ]] || die "identity options are required"
  validate_workflow_id "$workflow_id"
}

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

verify_state() {
  parse_identity_options "$@"
  resolve_repository
  state_path_for
  read_state
  jq -e \
    --arg workflow_id "$workflow_id" \
    --arg workflow "$workflow" \
    --arg subject_kind "$subject_kind" \
    --arg subject "$subject" \
    --arg repository_common_dir "$common_dir" \
    '.workflow_id == $workflow_id and .identity.workflow == $workflow and .identity.subject_kind == $subject_kind and .identity.subject == $subject and .identity.repository_common_dir == $repository_common_dir' \
    "$state_file" >/dev/null || die "state identity does not match"
  jq '.' "$state_file"
}

update_state() {
  local namespace="" expected_revision="" value_file=""
  while (($#)); do
    case "$1" in
      --workflow-id) require_value "$1" "${2:-}"; workflow_id="$2"; shift 2 ;;
      --namespace) require_value "$1" "${2:-}"; namespace="$2"; shift 2 ;;
      --expected-revision) require_value "$1" "${2:-}"; expected_revision="$2"; shift 2 ;;
      --value-file) require_value "$1" "${2:-}"; value_file="$2"; shift 2 ;;
      *) die "unknown option: $1" ;;
    esac
  done
  [[ -n "${workflow_id:-}" && -n "$namespace" && -n "$expected_revision" && -n "$value_file" ]] || die "update options are required"
  validate_workflow_id "$workflow_id"
  validate_namespace "$namespace"
  [[ "$expected_revision" =~ ^[0-9]+$ ]] || die "expected revision must be a non-negative integer"
  validate_private_json_object "$value_file"
  resolve_repository
  state_path_for
  acquire_lock
  trap release_lock EXIT
  read_state
  [[ "$(jq -r '.status' "$state_file")" == "active" ]] || die "state is not active"
  [[ "$(jq -r '.revision' "$state_file")" == "$expected_revision" ]] || die "state revision does not match"
  local now draft
  now="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  draft="$(mktemp)"
  jq \
    --arg namespace "$namespace" \
    --arg now "$now" \
    --argjson value "$validated_json" \
    '.namespaces[$namespace] = $value | .revision += 1 | .updated_at = $now' \
    "$state_file" >"$draft"
  write_state "$draft"
  rm -f "$draft"
  jq --arg namespace "$namespace" '{workflow_id, status, revision, namespace: $namespace, value: .namespaces[$namespace]}' "$state_file"
}

complete_state() {
  local expected_revision="" result_file=""
  while (($#)); do
    case "$1" in
      --workflow-id) require_value "$1" "${2:-}"; workflow_id="$2"; shift 2 ;;
      --expected-revision) require_value "$1" "${2:-}"; expected_revision="$2"; shift 2 ;;
      --result-file) require_value "$1" "${2:-}"; result_file="$2"; shift 2 ;;
      *) die "unknown option: $1" ;;
    esac
  done
  [[ -n "${workflow_id:-}" && -n "$expected_revision" && -n "$result_file" ]] || die "complete options are required"
  validate_workflow_id "$workflow_id"
  [[ "$expected_revision" =~ ^[0-9]+$ ]] || die "expected revision must be a non-negative integer"
  validate_private_json_object "$result_file"
  resolve_repository
  state_path_for
  acquire_lock
  trap release_lock EXIT
  read_state
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

main() {
  require_command git
  require_command jq
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
