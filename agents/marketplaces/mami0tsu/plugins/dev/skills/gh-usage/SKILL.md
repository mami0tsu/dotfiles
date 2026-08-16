---
name: gh-usage
description: GitHub CLI を使い、Issue、Discussion、pull request、GitHub Actions、review comment を読み取り、Draft pull request、pending review、stacked pull request を安全に扱うときに使う。
---

# GitHub CLI Usage

`gh` で GitHub の情報を読み取り、Draft pull request と submit 前の pending review だけを書き込む。

## 対象範囲

- Issue を読む：[Issue と Discussion](references/issues-and-discussions.md)
- Discussion を読む：[Issue と Discussion](references/issues-and-discussions.md)
- pull request を読む：[pull request](references/pull-requests.md)
- GitHub Actions の状態と失敗したログを読む：[Actions と review comment](references/actions-and-review-comments.md)
- review comment と解決状態を読む：[Actions と review comment](references/actions-and-review-comments.md)
- Draft pull request を作成する：[pull request](references/pull-requests.md)
- pending review を作成または更新する：[pending review](references/pending-reviews.md)
- Draft pull request を stack 化する：[stacked pull request](references/stacked-pull-requests.md)

branch の作成、commit、rebase、push は [git-usage](../git-usage/SKILL.md) に委譲する。

Issue、Discussion、Conversation comment、即時公開 review comment、review submit、thread resolve、pull request の close、merge、ready 化、GitHub Actions の rerun、cancel、delete は対象外である。

## 共通の判断規則

開始時の認証と repository の確認は、[共通の事前確認](references/common.md) に従う。

一覧から探す必要があるときだけ `list` を使い、識別できたら番号または URL に切り替える。

`--json` では、判断に必要な field だけを指定する。

JSON 全体を取得してから必要な値を探す方法は取らない。

`gh api graphql` の mutation は、[pending review](references/pending-reviews.md) に記載した4種類だけを完全一致する形で使う。

`submitPullRequestReview`、`resolveReviewThread`、`unresolveReviewThread`、即時公開 comment を作る mutation は実行しない。

その他の GraphQL mutation、`gh api` の更新系 HTTP method、書き込み系の `gh` subcommand は実行しない。

Draft pull request の作成前には、対象 branch が push 済みであることを `git-usage` で確認する。

`gh pr create` には `--head`、`--base`、`--title`、`--body-file`、`--draft` を明示する。

この指定により、`gh pr create` が branch を push または fork する対話へ進むことを避ける。

`gh stack link` は、個別作成と検証を終えた既存 Draft pull request の URL だけを bottom から top の順で渡す。

`--open` は指定しない。

## ヘルプのフォールバック

検証済みの `gh 2.96.0 (nixpkgs)` では、通常経路の前に `--help` を読まず、対応する reference のコマンドを使う。

次の場合だけ、必要な subcommand の help を確認する。

- 要求された操作が対象範囲にない。
- `gh --version` が記録済みのバージョンと異なり、対象コマンドの構文または挙動を確認できない。
- 実行結果が未対応 option または変更された構文を示す。

たとえば pull request 作成だけを確認するときは、`gh pr create --help` を使う。

念のため `gh --help` を読むことはしない。

## 検証記録

構造確認と Agent シナリオ試験は、[検証記録](references/validation.md) に残す。
