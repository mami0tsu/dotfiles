# create-draft-pr

指定した内容からDraft PRを作る[^gh-pr-create]。

## 入力

- `owner/repo`形式のrepository名
- base branch
- head branch
- title
- body file
- `find-pull-request`ユースケースの空の検索結果

## 出力

- Draft PRのURL

## 制約

- base branch、head branch、title、body fileを省略しない。
- head branchをremoteへpush済みとする。
- Ready for reviewのpull requestを作らない。
- reviewerとprojectを追加しない。

## 手順

### 1. Draft PRを作る

```sh
gh pr create --repo <owner>/<repo> --draft \
  --base <base-branch> --head <head-branch> \
  --title '<title>' --body-file <body-file>
```

### 2. 作成結果を確認する

```sh
gh pr view <created-url> --repo <owner>/<repo> \
  --json number,isDraft,baseRefName,headRefName,title,body,url
```

Draft状態、base branch、head branch、title、bodyが入力と一致することを確認する。
bodyは末尾の改行だけを正規化して比較する。

### 3. 結果を返す

コマンドが出力したDraft PRのURLを返す。

[^gh-pr-create]: [GitHub CLI `gh pr create` manual](https://cli.github.com/manual/gh_pr_create)
