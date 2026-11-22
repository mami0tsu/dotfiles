---
name: setup-repository
description: 調査または実装のためにリポジトリのデフォルトブランチを最新化する。
compatibility: Requires Bash, CUE (cue), Git, ghq, and GitHub CLI (gh).
allowed-tools: >-
  Bash(bash */skills/setup-repository/scripts/setup-repository.sh *)
---

# Setup Repository

## 入力

| 項目 | 内容 |
| --- | --- |
| リポジトリ | 準備するリポジトリの URL |

## 出力

| 成果物 | 内容 |
| --- | --- |
| リポジトリ | ローカルの絶対パスと最新のデフォルトブランチのコミット |

## 手順

1. [setup-repository.sh](scripts/setup-repository.sh) にリポジトリの URL を渡して実行する。
1. リポジトリの絶対パスとコミットを loop に返す。
