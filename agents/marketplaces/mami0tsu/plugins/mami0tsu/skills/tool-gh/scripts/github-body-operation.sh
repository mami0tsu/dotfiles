#!/usr/bin/env bash

set -euo pipefail

# private body fileと終了時cleanupに使う状態を保持する。
private_directory=""
body_file=""

# 入力検査とエラー処理を共通化する。

# 呼び出し元へ一定形式のエラーを返して終了する。
die() {
  printf '%s\n' "error: $*" >&2
  exit 1
}

# optionの直後に空でない値があることを確認する。
require_value() {
  local option="$1" value="${2:-}"
  [[ -n "$value" ]] || die "missing value for $option"
}

# 成否やsignalにかかわらず、専用processが作った一時成果物を削除する。
cleanup() {
  if [[ -n "$body_file" && ( -f "$body_file" || -L "$body_file" ) ]]; then
    rm -f -- "$body_file"
  fi
  if [[ -n "$private_directory" && -d "$private_directory" && ! -L "$private_directory" ]]; then
    rmdir -- "$private_directory" 2>/dev/null || true
  fi
}

# signalを失敗終了へ変換し、EXIT trapでcleanupする。
handle_signal() {
  exit 1
}

# 標準入力を権限`0600`の一時body fileへ保存する。
prepare_body() {
  umask 077
  private_directory="$(mktemp -d "${TMPDIR:-/tmp}/mami0tsu-gh-body.XXXXXX")"
  body_file="$private_directory/body.md"
  command cat >"$body_file" || die "failed to write private body"
  chmod 600 "$body_file"
}

# Issue作成に必要な値だけを読み取り、本文をfile経由で渡す。
create_issue() {
  local repository="" title=""
  while (($#)); do
    case "$1" in
      --repo) require_value "$1" "${2:-}"; repository="$2"; shift 2 ;;
      --title) require_value "$1" "${2:-}"; title="$2"; shift 2 ;;
      *) die "unknown option for issue-create: $1" ;;
    esac
  done
  [[ -n "$repository" && -n "$title" ]] || die "issue-create options are required"
  prepare_body
  gh issue create --repo "$repository" --title "$title" --body-file "$body_file"
}

# Issue更新に必要な値だけを読み取り、本文をfile経由で渡す。
update_issue() {
  local repository="" issue="" title=""
  while (($#)); do
    case "$1" in
      --repo) require_value "$1" "${2:-}"; repository="$2"; shift 2 ;;
      --issue) require_value "$1" "${2:-}"; issue="$2"; shift 2 ;;
      --title) require_value "$1" "${2:-}"; title="$2"; shift 2 ;;
      *) die "unknown option for issue-update: $1" ;;
    esac
  done
  [[ -n "$repository" && -n "$issue" && -n "$title" ]] || die "issue-update options are required"
  prepare_body
  gh issue edit "$issue" --repo "$repository" --title "$title" --body-file "$body_file"
}

# Draft PR作成に必要な値だけを読み取り、本文をfile経由で渡す。
create_draft_pr() {
  local repository="" base_branch="" head_branch="" title=""
  while (($#)); do
    case "$1" in
      --repo) require_value "$1" "${2:-}"; repository="$2"; shift 2 ;;
      --base) require_value "$1" "${2:-}"; base_branch="$2"; shift 2 ;;
      --head) require_value "$1" "${2:-}"; head_branch="$2"; shift 2 ;;
      --title) require_value "$1" "${2:-}"; title="$2"; shift 2 ;;
      *) die "unknown option for pr-create: $1" ;;
    esac
  done
  [[ -n "$repository" && -n "$base_branch" && -n "$head_branch" && -n "$title" ]] || die "pr-create options are required"
  prepare_body
  gh pr create --repo "$repository" --draft --base "$base_branch" --head "$head_branch" --title "$title" --body-file "$body_file"
}

# 許可したGitHub本文操作のうち一つだけを実行する。
main() {
  command -v gh >/dev/null 2>&1 || die "required command not found: gh"
  trap cleanup EXIT
  trap handle_signal HUP INT TERM
  local command_name="${1:-}"
  [[ -n "$command_name" ]] || die "command is required"
  shift
  case "$command_name" in
    issue-create) create_issue "$@" ;;
    issue-update) update_issue "$@" ;;
    pr-create) create_draft_pr "$@" ;;
    *) die "unknown command: $command_name" ;;
  esac
}

main "$@"
