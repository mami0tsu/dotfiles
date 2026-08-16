# stacked pull request

## 情報源

- 公式ドキュメント：[GitHub Stacked Pull Requests](https://gh.io/stacks)
- CLI help：`gh stack link --help`
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`、`gh stack version 0.1.0`
- バージョン確認：`gh --version`、`gh stack --version`

## 既存 Draft pull request を stack 化する

### 目的

個別に作成済みの Draft pull request を、依存順が明示された一つの stack にする。

### 前提条件

各 pull request は [pull request](pull-requests.md) の手順で template 付き Draft として作成し、title、body、base、head、Draft 状態を検証する。

各 pull request URL と、ticket の block 関係から確定した bottom から top への線形順序を取得する。

複数の blocker stack へ分岐する場合は実行しない。

各 pull request の stack 所属を read-only query で取得する。

```sh
gh api graphql \
  -F owner='<owner>' -F name='<repo>' -F number=<pr-number> \
  -f query='
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          number
          url
          stack { id number baseRefName size }
          stackEntry { id position stack { id number } }
        }
      }
    }
  '
```

どの stack にも属さないか、同じ stack に期待順で属することを確認する。

### 推奨コマンド

既存 pull request URL を bottom から top の順で渡す。

```sh
gh stack link --remote origin \
  <bottom-pr-url> <next-pr-url> [<top-pr-url>...]
```

新規 pull request を自動作成しないよう、branch 名ではなく検証済み PR URL だけを使う。

`--open`は指定しない。

### 結果の確認

各 pull request を再取得し、title、body、base、head、`isDraft: true`を確認する。

```sh
gh pr view <pr-url> --repo <owner>/<repo> \
  --json number,title,body,baseRefName,headRefName,isDraft,url
```

`gh stack view`は local stack tracking を前提とするため、`link`だけを使う flow の正本確認には使わない。

GitHub が返した stack URL または stack number と、bottom から top の PR URL 一覧を workflow state に保存する。

### 停止条件

PR URL が2件未満、順序が線形でない、別 repository の PR が混在する、PR が Draft でない場合は停止する。

既存 PR の base が期待順と異なる場合、`gh stack link`が base を変更することを人間の承認範囲に含む場合だけ実行する。

すでに別 stack に属する PR が含まれる場合は、自動で unstack または移動しない。

`gh stack submit`、`gh stack merge`、`gh stack unstack`は使わない。

### 代表的な失敗

stacked PR が repository で利用できない場合は、通常 PR のまま続行せず停止する。

一部 PR の base だけが更新された場合は再実行せず、全 PR の現在値と成功した変更を報告する。

branch push または新規 PR 作成が始まった場合は、PR URL 以外の入力が混入していないか確認する。
