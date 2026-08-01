#!/usr/bin/env bash
set -euo pipefail

packages=(
  apm
  ax
  codex
  difit
  roots
  git-wt
  zsh-defer-src
  git-open-src
)

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

  if [[ "$(uname -s)" == "Darwin" ]]; then
    file_mode="$(stat -f '%Lp' "$file")"
  else
    file_mode="$(stat -c '%a' "$file")"
  fi
  chmod "$file_mode" "$temporary_file"
  mv "$temporary_file" "$file"
  trap - RETURN
}

changed_revisions=()

if [[ "$mode" == "changed" ]]; then
  for package in "${packages[@]}"; do
    nix run 'nixpkgs#nix-update' -- \
      --flake \
      --system aarch64-darwin \
      --version=skip \
      "$package"
  done
fi

update_legacy_plugin_hashes

nix flake check --no-build --no-update-lock-file
