#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: renovate-update-nix-hashes.sh [--changed | --all | --check]

  --changed  Update local packages and hashes for legacy plugin revisions changed from HEAD (default).
  --all      Update hashes for every legacy plugin revision only.
  --check    Verify every legacy plugin hash without modifying files.
EOF
}

mode="changed"
case "${1:---changed}" in
  --changed)
    ;;
  --all)
    mode="all"
    ;;
  --check)
    mode="check"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 2
fi

revision_was_changed() {
  local candidate="$1"
  local changed_revision

  for changed_revision in "${changed_revisions[@]}"; do
    [[ "$candidate" == "$changed_revision" ]] && return 0
  done

  return 1
}

revision_was_matched() {
  local candidate="$1"
  local matched_revision

  for matched_revision in "${matched_revisions[@]}"; do
    [[ "$candidate" == "$matched_revision" ]] && return 0
  done

  return 1
}

update_legacy_plugin_hashes() {
  local file="nix/home-manager/nixvim/legacy-plugins.nix"
  local file_directory
  local file_basename
  local temporary_file
  local file_mode
  local line
  local owner=""
  local repo=""
  local revision=""
  local existing_hash=""
  local hash
  local indentation
  local matched_revisions=()

  [[ -f "$file" ]] || return 0

  if [[ "$mode" == "changed" ]]; then
    while IFS= read -r line; do
      if [[ "$line" =~ ^\+[[:space:]]*rev\ =\ \"([a-f0-9]{40})\"\;$ ]]; then
        changed_revisions+=("${BASH_REMATCH[1]}")
      fi
    done < <(git diff --no-ext-diff --unified=0 HEAD -- "$file")

    ((${#changed_revisions[@]})) || return 0
  fi

  file_directory="$(dirname "$file")"
  file_basename="$(basename "$file")"
  temporary_file="$(mktemp "${file_directory}/.${file_basename}.tmp.XXXXXX")"
  trap 'rm -f "$temporary_file"' RETURN

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^[[:space:]]*#\ renovate:\ datasource=git-refs\ packageName=https://github\.com/([^/[:space:]]+)/([^[:space:]]+)\ currentValue=[^[:space:]]+[[:space:]]*$ ]]; then
      if [[ -n "$owner" || -n "$repo" || -n "$revision" ]]; then
        printf 'incomplete Renovate metadata in %s\n' "$file" >&2
        return 1
      fi
      owner="${BASH_REMATCH[1]}"
      repo="${BASH_REMATCH[2]}"
    elif [[ -n "$owner" && "$line" =~ ^[[:space:]]*rev\ =\ \"([a-f0-9]{40})\"\;$ ]]; then
      revision="${BASH_REMATCH[1]}"
    elif [[ -n "$revision" && "$line" =~ ^([[:space:]]*)hash\ =\ \"[^\"]+\"\;$ ]]; then
      indentation="${BASH_REMATCH[1]}"
      existing_hash="${line#*\"}"
      existing_hash="${existing_hash%\";}"
      if [[ "$mode" == "all" || "$mode" == "check" ]] || revision_was_changed "$revision"; then
        matched_revisions+=("$revision")
        hash="$(nix-prefetch-url --unpack "https://github.com/$owner/$repo/archive/$revision.tar.gz")"
        hash="$(nix hash convert --hash-algo sha256 --to sri "$hash")"
        if [[ "$mode" == "check" ]]; then
          if [[ "$hash" != "$existing_hash" ]]; then
            printf 'stale hash for %s/%s at %s\n' "$owner" "$repo" "$revision" >&2
            return 1
          fi
        else
          line="${indentation}hash = \"$hash\";"
        fi
      fi
      owner=""
      repo=""
      revision=""
    fi

    printf '%s\n' "$line" >> "$temporary_file"
  done < "$file"

  if [[ -n "$owner" || -n "$repo" || -n "$revision" ]]; then
    printf 'incomplete Renovate metadata in %s\n' "$file" >&2
    return 1
  fi

  if [[ "$mode" == "check" ]]; then
    return 0
  fi

  if [[ "$mode" == "changed" ]]; then
    for revision in "${changed_revisions[@]}"; do
      if ! revision_was_matched "$revision"; then
        printf 'changed revision %s was not matched by Renovate metadata in %s\n' "$revision" "$file" >&2
        return 1
      fi
    done
  fi

  if ! file_mode="$(stat -c '%a' "$file" 2>/dev/null)"; then
    file_mode="$(stat -f '%Lp' "$file")"
  fi
  chmod "$file_mode" "$temporary_file"
  mv "$temporary_file" "$file"
  trap - RETURN
}

replace_single_hash() {
  local file="$1"
  local hash="$2"
  local file_directory
  local file_basename
  local temporary_file
  local file_mode
  local line
  local indentation
  local hash_count=0
  local hash_pattern='^([[:space:]]*)hash[[:space:]]*=[[:space:]]*"[^"]+";$'

  file_directory="$(dirname "$file")"
  file_basename="$(basename "$file")"
  temporary_file="$(mktemp "${file_directory}/.${file_basename}.tmp.XXXXXX")"
  trap 'rm -f "$temporary_file"' RETURN

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ $hash_pattern ]]; then
      indentation="${BASH_REMATCH[1]}"
      line="${indentation}hash = \"$hash\";"
      hash_count=$((hash_count + 1))
    fi
    printf '%s\n' "$line" >> "$temporary_file"
  done < "$file"

  if [[ "$hash_count" != 1 ]]; then
    printf 'expected one hash in %s, found %s\n' "$file" "$hash_count" >&2
    return 1
  fi

  if ! file_mode="$(stat -c '%a' "$file" 2>/dev/null)"; then
    file_mode="$(stat -f '%Lp' "$file")"
  fi
  chmod "$file_mode" "$temporary_file"
  mv "$temporary_file" "$file"
  trap - RETURN
}

update_source_package_hash() {
  local package="$1"
  local file="nix/packages/${package}.nix"
  local line
  local owner=""
  local repo=""
  local revision=""
  local hash
  local owner_pattern='^[[:space:]]*owner[[:space:]]*=[[:space:]]*"([^"]+)";$'
  local repo_pattern='^[[:space:]]*repo[[:space:]]*=[[:space:]]*"([^"]+)";$'
  local revision_pattern='^[[:space:]]*rev[[:space:]]*=[[:space:]]*"([a-f0-9]{40})";$'

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ $owner_pattern ]]; then
      owner="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ $repo_pattern ]]; then
      repo="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ $revision_pattern ]]; then
      revision="${BASH_REMATCH[1]}"
    fi
  done < "$file"

  if [[ -z "$owner" || -z "$repo" || -z "$revision" ]]; then
    printf 'incomplete GitHub source metadata in %s\n' "$file" >&2
    return 1
  fi

  hash="$(nix-prefetch-url --unpack "https://github.com/$owner/$repo/archive/$revision.tar.gz")"
  hash="$(nix hash convert --hash-algo sha256 --to sri "$hash")"
  replace_single_hash "$file" "$hash"
}

update_release_package_hash() {
  local package="$1"
  local file="nix/packages/${package}.nix"
  local url
  local hash

  url="$(nix eval --raw ".#packages.aarch64-darwin.${package}.src.url")"
  hash="$(nix-prefetch-url "$url")"
  hash="$(nix hash convert --hash-algo sha256 --to sri "$hash")"
  replace_single_hash "$file" "$hash"
}

changed_revisions=()

if [[ "$mode" == "changed" ]]; then
  changed_packages=()
  while IFS= read -r file; do
    case "$file" in
      nix/packages/default.nix|nix/packages/lib/*)
        continue
        ;;
      nix/packages/*.nix)
        changed_packages+=("${file##*/}")
        changed_packages[${#changed_packages[@]}-1]="${changed_packages[${#changed_packages[@]}-1]%.nix}"
        ;;
    esac
  done < <(git diff --name-only HEAD -- nix/packages)

  for package in "${changed_packages[@]}"; do
    case "$package" in
      git-open-src|zsh-defer-src)
        update_source_package_hash "$package"
        ;;
      apm|ax|codex|gh-aw|gh-stack|git-wt|roots)
        update_release_package_hash "$package"
        ;;
      *)
        nix run 'nixpkgs#nix-update' -- \
          --flake \
          --system aarch64-darwin \
          --version=skip \
          "$package"
        ;;
    esac
  done

  if ! git diff --quiet HEAD -- .github/textlint/package.json .github/textlint/pnpm-lock.yaml; then
    nix run 'nixpkgs#nix-update' -- \
      --flake \
      --system aarch64-darwin \
      --version=skip \
      textlint
  fi
fi

update_legacy_plugin_hashes

nix flake check --no-build --no-update-lock-file
