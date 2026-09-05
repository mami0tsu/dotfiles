#!/usr/bin/env bash

set -euo pipefail

# 入力検査とエラー処理を共通化する。

# 呼び出し元へ一定形式のエラーを返して終了する。
die() {
  printf '%s\n' "error: $*" >&2
  exit 1
}

# OSごとの差を吸収してfileまたはdirectoryの所有者IDを取得する。
owner_id_of() {
  local path="$1"
  if stat -f '%u' "$path" >/dev/null 2>&1; then
    stat -f '%u' "$path"
  else
    stat -c '%u' "$path"
  fi
}

# 権限を限定したdirectoryで標準入力をbody fileへ保存する。
create_private_body() {
  local private_directory body_file
  umask 077
  private_directory="$(mktemp -d "${TMPDIR:-/tmp}/mami0tsu-gh-body.XXXXXX")"
  body_file="$private_directory/body.md"
  trap 'rm -f -- "$body_file"; rmdir -- "$private_directory" 2>/dev/null || true; exit 1' HUP INT TERM
  if ! command cat >"$body_file"; then
    rm -f -- "$body_file"
    rmdir -- "$private_directory" 2>/dev/null || true
    trap - HUP INT TERM
    die "failed to write private body"
  fi
  trap - HUP INT TERM
  chmod 600 "$body_file"
  printf '%s\n' "$body_file"
}

# 専用scriptが作った対象だけを検査し、一時fileとdirectoryを削除する。
remove_private_body() {
  local body_file="$1" private_directory expected_prefix
  [[ -n "$body_file" && "$body_file" == /* ]] || die "private body path must be absolute"
  private_directory="$(dirname "$body_file")"
  expected_prefix="${TMPDIR:-/tmp}/mami0tsu-gh-body."
  [[ "$private_directory" == "$expected_prefix"* ]] || die "private body directory is outside the managed location"
  [[ "$(basename "$body_file")" == "body.md" ]] || die "unexpected private body file name"
  [[ -d "$private_directory" && ! -L "$private_directory" ]] || die "private body directory is invalid"
  [[ -f "$body_file" && ! -L "$body_file" ]] || die "private body file is invalid"
  [[ "$(owner_id_of "$private_directory")" == "$(id -u)" ]] || die "private body directory has another owner"
  [[ "$(owner_id_of "$body_file")" == "$(id -u)" ]] || die "private body file has another owner"
  rm -f -- "$body_file"
  rmdir -- "$private_directory"
}

# createとremoveのどちらか一つだけを実行する。
main() {
  local command_name="${1:-}"
  [[ -n "$command_name" ]] || die "command is required"
  shift
  case "$command_name" in
    create)
      (($# == 0)) || die "create does not accept options"
      create_private_body
      ;;
    remove)
      [[ "${1:-}" == "--file" && -n "${2:-}" && $# == 2 ]] || die "remove requires --file"
      remove_private_body "$2"
      ;;
    *) die "unknown command: $command_name" ;;
  esac
}

main "$@"
