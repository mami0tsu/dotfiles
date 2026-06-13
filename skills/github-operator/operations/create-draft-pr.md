# create-draft-pr

remote に push 済みの branch から Draft PR を作成する。

## 前提

- branch は remote に push 済み
- detached HEAD ではない
- base branch は、ユーザー指定がなければ GitHub repository default branch
- PR body は repository template を最優先
- MCP で作成し、失敗時だけ `gh pr create --draft` に fallback する

## 手順

1. `common/context.md`、`common/safety.md`、`common/mcp-cli-policy.md`、`common/pr-template.md`、`common/execution-plan.md` を読む。
2. repository と current branch を解決する。
3. current branch が remote に存在しない場合は中止し、次の例を示す。
   ```sh
   git push -u origin <branch-name>
   ```
4. GitHub repository default branch を取得する。ユーザー指定の base があればそれを使う。
5. title を作る。
   - 通常: `<short-summary> <ticket-id>`
   - `wip/`: `WIP: <short-summary>`
6. PR template を探す。複数あればユーザーに選択させる。
7. template がなければ fallback template を使う。
8. `wip/` branch なら body 冒頭に warning alert を入れる。
9. 実行計画を表示する。
10. MCP で Draft PR を作成する。
11. MCP 作成が失敗した場合だけ、`gh pr create --draft` に fallback する。
12. 重複 PR などで作成に失敗した場合は、エラー内容を伝え、既存 PR がある可能性を確認して案内する。

## MCP

MCP では `create_pull_request` 相当の tool を使い、`draft: true`、`base`、`head`、`title`、`body` を明示する。

## CLI fallback

```sh
gh pr create --draft --base <base-branch> --head <head-branch> --title "<title>" --body-file <body-file>
```

`gh` fallback を使う前に認証状態を確認する。

```sh
gh auth status
```
