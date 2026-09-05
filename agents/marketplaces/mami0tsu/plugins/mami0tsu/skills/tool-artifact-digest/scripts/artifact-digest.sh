#!/usr/bin/env bash

set -euo pipefail

# 入力検査とエラー処理を共通化する。

# 呼び出し元へ一定形式のエラーを返して終了する。
die() {
  printf '%s\n' "error: $*" >&2
  exit 1
}

# 実行に必要なcommandがPATH上にあることを確認する。
require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

# 入力fileの種類、所有者、権限を検査する。
validate_private_file() {
  local file="$1"
  [[ -f "$file" && -r "$file" ]] || die "input must be a readable regular file: $file"
  local owner_id permission_mode
  if stat -f '%u' "$file" >/dev/null 2>&1; then
    owner_id="$(stat -f '%u' "$file")"
    permission_mode="$(stat -f '%Lp' "$file")"
  else
    owner_id="$(stat -c '%u' "$file")"
    permission_mode="$(stat -c '%a' "$file")"
  fi
  [[ "$owner_id" == "$(id -u)" ]] || die "input file must be owned by the current user"
  (( (8#$permission_mode & 077) == 0 )) || die "input file must not be accessible by group or other users"
}

# file指定時と標準入力時を同じbyte streamとして後続処理へ渡す。
read_input() {
  local input_file="$1"
  if [[ -n "$input_file" ]]; then
    validate_private_file "$input_file"
    command cat -- "$input_file"
  else
    command cat
  fi
}

# 利用可能な標準commandでSHA-256を求め、共通の出力形式へ変換する。
sha256_stream() {
  local digest
  if command -v shasum >/dev/null 2>&1; then
    digest="$(shasum -a 256 | awk '{print $1}')"
  elif command -v sha256sum >/dev/null 2>&1; then
    digest="$(sha256sum | awk '{print $1}')"
  else
    die "shasum or sha256sum is required"
  fi
  [[ "$digest" =~ ^[a-f0-9]{64}$ ]] || die "failed to calculate SHA-256 digest"
  printf 'sha256:%s\n' "$digest"
}

# textの改行形式と末尾改行だけを正規化する。
digest_text() {
  local input_file="$1"
  read_input "$input_file" \
    | jq -jRs 'gsub("\r\n"; "\n") | gsub("\r"; "\n") | sub("\n+$"; "") + "\n"' \
    | sha256_stream
}

# JSONのkey順と空白を正規化し、値とarray順序を保持する。
digest_json() {
  local input_file="$1"
  read_input "$input_file" \
    | jq -cS '.' \
    | sha256_stream
}

# modeと任意のprivate fileを読み取り、対応する正規化だけを実行する。
main() {
  require_command jq
  require_command awk
  require_command stat
  local mode="${1:-}" input_file=""
  [[ -n "$mode" ]] || die "mode is required"
  shift
  while (($#)); do
    case "$1" in
      --file)
        [[ -n "${2:-}" ]] || die "missing value for --file"
        input_file="$2"
        shift 2
        ;;
      *) die "unknown option: $1" ;;
    esac
  done
  case "$mode" in
    text) digest_text "$input_file" ;;
    json) digest_json "$input_file" ;;
    *) die "unknown mode: $mode" ;;
  esac
}

main "$@"
