# create-draft-pr

指定した内容からDraft PRを作る[^gh-pr-create]。

## 入力

- `host/owner/repo`形式のrepository名
- base branch
- head branch
- title
- 標準入力から渡す承認済み本文
- `find-pull-request`ユースケースの空の検索結果

## 出力

- Draft PRのURL

## 制約

- base branch、head branch、title、本文を省略しない。
- head branchをremoteへpush済みとする。
- Ready for reviewのpull requestを作らない。
- reviewerとprojectを追加しない。

## 手順

### 1. Draft PRを作る

```sh
bash "<plugin-root>/skills/tool-gh/scripts/github-body-operation.sh" pr-create \
  --repo <host>/<owner>/<repo> --base <base-branch> --head <head-branch> \
  --title '<title>'
```

承認済み本文を標準入力へ送り終えたらEOFを送る。
Scriptはprivate body fileを作成し、`gh pr create`の終了時に削除する。

### 2. 作成結果を確認する

```sh
gh pr view <created-url> --repo <host>/<owner>/<repo> \
  --json number,isDraft,baseRefName,headRefName,title,body,url
```

Draft状態、base branch、head branch、title、bodyが入力と一致することを確認する。
bodyは末尾の改行だけを正規化して比較する。

### 3. 結果を返す

コマンドが出力したDraft PRのURLを返す。

[^gh-pr-create]: [GitHub CLI `gh pr create` manual](https://cli.github.com/manual/gh_pr_create)
