# link-pull-request-stack

個別に作成済みのDraft PRを線形のstackへ関連付ける[^github-stacks]。

## 入力

- remote
- bottomからtopへ並べた2件以上のDraft PR URL
- 各pull requestの`inspect-pull-request`結果
- 各pull requestの`inspect-pull-request-stack`結果

## 出力

- stack URLまたはstack番号
- bottomからtopへ並べたpull request URL

## 制約

- 同じrepositoryのDraft PRだけを使う。
- pull requestの順序は線形とする。
- 別のstackに所属するpull requestを含めない。
- `gh stack submit`、`gh stack merge`、`gh stack unstack`を実行しない。
- `--open`を指定しない。

## 手順

### 1. Pull requestをstackへ関連付ける

```sh
gh stack link --remote <remote> \
  <bottom-pr-url> <next-pr-url> [<top-pr-url>...]
```

### 2. Pull requestを取得する

各pull requestへ`inspect-pull-request`ユースケースと`inspect-pull-request-stack`ユースケースを実行する。

### 3. 結果を返す

stack URLまたはstack番号と、bottomからtopへ並べたpull request URLを返す。

[^github-stacks]: [GitHub Stacked Pull Requests](https://gh.io/stacks)
