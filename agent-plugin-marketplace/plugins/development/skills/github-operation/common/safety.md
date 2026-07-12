# 安全ルール

## 書き込み操作

初期版で許可する GitHub 書き込み操作は Draft PR 作成だけ。

次の操作は実行しない。

- PR comment 追加
- review comment reply
- review submit
- review thread resolve/unresolve
- Issue/Discussion 作成、コメント、close
- label、assignee、milestone の変更
- PR close
- branch delete
- merge
- workflow rerun

必要になった場合は、別 operation として設計する。

## Git 操作

この skill では branch 作成、commit、push、rebase を実行しない。Draft PR 作成に必要な branch が remote にない場合は、push コマンド例を示して中止する。

## GitHub CLI

`gh api` は read-only endpoint または read-only GraphQL query の取得に限定する。write 系 endpoint と GraphQL mutation は使わない。

GitHub CLI を使う前に `gh auth status` を確認する。`gh` が未認証の場合は MCP fallback せずに中止し、`gh auth status` の結果を伝え、ユーザーに認証を依頼する。認証操作はこの skill では実行しない。

GitHub への書き込みは `gh pr create --draft` に限定する。`gh api` の write endpoint、PR comment、review reply、thread resolve などは使わない。

## `wip/` Draft PR

`wip/` branch の Draft PR 作成は許可する。ただし、PR title は `WIP: <short-summary>` とし、PR body の冒頭に次の alert を入れる。

```markdown
> [!WARNING]
> 本 PR は仮実装なのでマージはしません。
```

`wip/` Draft PR は通常 merge 対象ではない。
