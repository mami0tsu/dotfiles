---
name: create-issue
description: レビュー済みの Issue の候補を GitHub に登録する。
compatibility: Requires Bash, CUE (cue), and GitHub CLI (gh).
allowed-tools: >-
  Read
  Bash(bash */skills/create-issue/scripts/search-issues.sh *)
  Bash(bash */skills/create-issue/scripts/create-issue.sh *)
---

# Create Issue

## 入力

| 項目 | 内容 |
| --- | --- |
| `factory.json` | Issue の管理先と上限を指定した設定 |
| Issue の候補 | レビュー済みの題名、本文ファイルと調査の根拠 |

## 出力

| 成果物 | 内容 |
| --- | --- |
| GitHub Issue | 登録した Issue |

## 手順

1. [search-issues.sh](scripts/search-issues.sh) に設定ファイルの絶対パスと候補を表す検索語を渡し、既存 Issue と照合する。
   重複する候補は登録しない。
1. [create-issue.sh](scripts/create-issue.sh) に設定ファイルの絶対パス、題名と本文ファイルの絶対パスを渡して実行する。
1. 登録した Issue の URL を返す。
