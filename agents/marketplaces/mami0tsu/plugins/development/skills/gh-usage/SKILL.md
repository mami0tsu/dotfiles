---
name: gh-usage
description: GitHub CLI を安全かつ効率的に使うためのリファレンス。Issue、Discussion、PR、review comment、GitHub Actions を確認するとき、または Draft PR を作成するときに使う。
---

# GitHub CLI Usage

GitHub の読み取りと定型操作には `gh` を優先する。

## 原則

- 最初に `gh auth status` と対象 repository を確認する。
- 一覧取得より、URL、Issue 番号、PR 番号による直接参照を優先する。
- 必要な JSON field だけを `--json` で取得する。
- GitHub MCP は、認証済みの `gh` で取得できない場合だけ使う。
- 書き込みは Draft PR 作成だけに限定し、その他の操作は読み取り専用とする。
- branch 作成、commit、rebase、push は `git-usage` に委譲する。

## よく使う操作

- Issue：`gh issue view <number>`
- Discussion：read-only の `gh api graphql` で取得する
- PR：`gh pr view <number>`
- CI：`gh pr checks <number>`、`gh run view <run-id> --log-failed`
- review comment：`gh api` で review と thread に必要な field を取得する
- Draft PR：`gh pr create --draft --base <base> --head <head> --title <title> --body-file -`

Draft PR の body は repository の PR template を優先する。
template がなければ、呼び出し元が指定する fallback template を使う。

## PR のタイトル

repository に規約があれば優先する。
規約がない場合は `<summary> <ticket-id>` とし、ticket ID の直前を半角スペース1文字で区切る。
