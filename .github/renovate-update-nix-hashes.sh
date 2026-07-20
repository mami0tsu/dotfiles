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

for package in "${packages[@]}"; do
  nix run 'nixpkgs#nix-update' -- \
    --flake \
    --system aarch64-darwin \
    --version=skip \
    "$package"
done

nix flake check --no-build --no-update-lock-file
