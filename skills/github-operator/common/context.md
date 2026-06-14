# GitHub 対象の解決

GitHub 操作の対象は推測せず、URL、repo 名、PR/Issue/Discussion 番号、または local git context から解決する。

## repository

ユーザーが `owner/repo` または GitHub URL を渡した場合はそれを優先する。

local checkout から解決する場合は、次を確認する。

```sh
git rev-parse --show-toplevel
git remote -v
git branch --show-current
```

remote URL から `owner/repo` を解決できない場合は、ユーザーに repo を確認する。

## current branch

Draft PR 作成時の `head` は current branch を使う。detached HEAD では Draft PR を作成しない。

```sh
git branch --show-current
```

remote に push 済みか確認できない場合、または head branch が GitHub 上に存在しない場合は Draft PR 作成を中止し、push コマンド例を示す。

## default branch

PR の base は、ユーザー指定がなければ GitHub repository の default branch を使う。正規経路は `gh repo view --json defaultBranchRef` とする。local の `origin/HEAD` より GitHub 側の repository metadata を優先する。

## PR

PR URL または番号がある場合はそれを使う。PR metadata は `gh pr view` で取得する。ユーザーが「現在の PR」と言った場合だけ、local branch から `gh pr view --json number,url` で解決してよい。

## Issue / Discussion

Issue/Discussion は、URL または明示番号があるものだけ読む。曖昧な「関連 Issue」「関連 Discussion」は検索で推測せず、対象をユーザーに確認する。
