#!/usr/bin/env bash
set -euo pipefail

verify_release() (
  package="$1"
  release="$(nix eval --json ".#packages.aarch64-darwin.${package}.passthru.release")"
  owner="$(jq -r .owner <<<"$release")"
  repo="$(jq -r .repo <<<"$release")"
  tag="$(jq -r .tag <<<"$release")"
  asset="$(jq -r .asset <<<"$release")"
  directory="$(mktemp -d)"
  trap 'rm -rf "$directory"' EXIT

  gh release download "$tag" --repo "$owner/$repo" --pattern "$asset" --dir "$directory"
  asset_path="$directory/$asset"
  digest="sha256:$(shasum -a 256 "$asset_path" | awk '{print $1}')"
  api_error="$directory/api-error"
  attestation_response=""

  if ! attestation_response="$(gh api "repos/$owner/$repo/attestations/$digest" 2>"$api_error")"; then
    if grep -q 'HTTP 404' "$api_error"; then
      attestations=0
    else
      cat "$api_error" >&2
      exit 1
    fi
  else
    attestations="$(jq -er '.attestations | length' <<<"$attestation_response")"
  fi

  if [[ "$attestations" != 0 ]]; then
    bundle_path="$directory/attestations.jsonl"
    jq -cer '.attestations[].bundle' <<<"$attestation_response" > "$bundle_path"
    predicate_types="$(
      jq -er '
        .attestations
        | map(.bundle.dsseEnvelope.payload | @base64d | fromjson | .predicateType)
        | unique[]
      ' <<<"$attestation_response"
    )"

    while IFS= read -r predicate_type; do
      case "$predicate_type" in
        https://in-toto.io/attestation/release/*)
          gh release verify-asset "$tag" "$asset_path" --repo "$owner/$repo"
          ;;
        https://slsa.dev/provenance/v1)
          gh attestation verify "$asset_path" \
            --bundle "$bundle_path" \
            --repo "$owner/$repo" \
            --predicate-type "$predicate_type" \
            --source-ref "refs/tags/$tag"
          ;;
        *)
          continue
          ;;
      esac
    done <<<"$predicate_types"
  fi
)

for package in "$@"; do
  case "$package" in
    apm|ax|codex|gh-aw|gh-stack|git-wt|roots)
      verify_release "$package"
      ;;
    *)
      continue
      ;;
  esac
done
