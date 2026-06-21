# create-draft-pr

remote に push 済みの branch から Draft PR を作成する。

## 前提

- branch は remote に push 済み
- detached HEAD ではない
- base branch は、ユーザー指定がなければ GitHub repository default branch
- PR body は repository template を最優先
- `gh pr create --draft` で作成し、認証以外の理由で失敗した場合だけ MCP fallback を検討する
- PR body は余計なファイルを作らず、stdin から `--body-file -` に渡す

## 手順

1. `common/context.md`、`common/safety.md`、`common/mcp-cli-policy.md`、`common/pr-template.md`、`common/execution-plan.md` を読む。
2. `gh auth status` を確認する。失敗した場合は中止し、認証を依頼する。
3. repository と current branch を解決する。
4. current branch が remote に存在しない場合は中止し、次の例を示す。
   ```sh
   git push -u origin <branch-name>
   ```
5. `gh repo view --json defaultBranchRef` で GitHub repository default branch を取得する。ユーザー指定の base があればそれを使う。
6. title を作る。
   - 通常: `<short-summary> <ticket-id>`
   - `wip/`: `WIP: <short-summary>`
7. `gh api` の read-only endpoint で PR template を探す。複数あればユーザーに選択させる。
8. template がなければ fallback template を使う。
9. `wip/` branch なら body 冒頭に warning alert を入れる。
10. 実行計画を表示する。
11. `gh pr create --draft` で Draft PR を作成する。
12. `gh pr create --draft` が認証以外の理由で失敗した場合だけ、ユーザー確認後に MCP fallback を使う。
13. 重複 PR などで作成に失敗した場合は、エラー内容を伝え、既存 PR がある可能性を確認して案内する。

## CLI

```sh
gh pr create --draft --base <base-branch> --head <head-branch> --title "<title>" --body-file -
```

`--body-file -` を使い、PR body は stdin から渡す。一時ファイルや repository 内の body file は作らない。

`gh` を使う前に認証状態を確認する。

```sh
gh auth status
```

## MCP fallback

MCP では `create_pull_request` 相当の tool を使い、`draft: true`、`base`、`head`、`title`、`body` を明示する。

MCP fallback は、`gh auth status` が成功しており、`gh pr create --draft` が認証以外の理由で失敗した場合だけ使う。実行前にユーザー確認を挟む。
