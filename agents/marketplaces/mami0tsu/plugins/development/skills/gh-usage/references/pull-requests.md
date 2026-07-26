# pull request

## 情報源

- 公式ドキュメント：[gh pr view](https://cli.github.com/manual/gh_pr_view)（確認コマンド：`gh pr view --help`）
- 公式ドキュメント：[gh pr create](https://cli.github.com/manual/gh_pr_create)（確認コマンド：`gh pr create --help`）
- 公式ドキュメント：[gh pr list](https://cli.github.com/manual/gh_pr_list)（確認コマンド：`gh pr list --help`）
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- バージョン確認：`gh --version`

## pull request を読む

### 目的

pull request の変更対象、review 状態、merge 状態、check 状態を読み取る。

### 前提条件

pull request 番号、URL、または head branch を取得する。

current branch に属する pull request を意図していない場合は、番号または URL を明示する。

### 推奨コマンド

概要と review 状態を読むときは、次を使う。

```sh
gh pr view <number-or-url> --repo <owner>/<repo> \
  --json number,title,body,state,isDraft,author,baseRefName,headRefName,reviewDecision,mergeStateStatus,url
```

変更規模または check の集約状態が必要な場合は、必要な field を追加する。

```sh
gh pr view <number-or-url> --repo <owner>/<repo> \
  --json number,changedFiles,additions,deletions,files,statusCheckRollup,url
```

既存の pull request を branch から確認するときは、状態を限定しない。

```sh
gh pr list --repo <owner>/<repo> --head <head> --state all \
  --json number,state,isDraft,title,url
```

### 結果の確認

返された `number`、`headRefName`、`baseRefName`、`url` が対象と一致することを確認する。

review の判断には `reviewDecision`、merge の判断には `mergeStateStatus`、Draft の判断には `isDraft` を使う。

### 停止条件

merge、close、reopen、ready for review、update branch、revert、comment、review は実行しない。

pull request が複数見つかった場合は、head branch と base branch のどれを対象にするかを利用者へ確認する。

### 代表的な失敗

argument を省略して意図しない current branch の pull request が選ばれた場合は、番号または URL を明示して再実行する。

`mergeStateStatus` が `UNKNOWN` の場合は、GitHub 側の計算中である可能性があるため、Actions の状態を確認してから利用者へ報告する。

`files` が多く出力が大きい場合は、対象 file を絞る必要があるか利用者へ確認する。

## Draft pull request を作成する

### 目的

push 済みの head branch から、指定した base branch への Draft pull request を作成する。

### 前提条件

branch の作成、commit、push は `git-usage` で完了している。

head branch、base branch、title、body file、対象 repository を取得する。

repository に pull request template がある場合は、それを本文の基礎にする。

template がない場合は、呼び出し元が指定した fallback template を body file に保存する。

作成前に既存の pull request がないことを確認する。

```sh
gh pr list --repo <owner>/<repo> --head <head> --state all \
  --json number,state,isDraft,title,url
```

### 推奨コマンド

base、head、title、本文を明示して Draft pull request を作成する。

```sh
gh pr create --repo <owner>/<repo> --draft \
  --base <base> --head <head> --title "<title>" --body-file <body-file>
```

repository の title 規約がなければ、`<summary> <ticket-id>` とする。

ticket ID の直前は半角スペース 1 文字で区切る。

### 結果の確認

作成時に出力された URL を控える。

続けて、作成した pull request が Draft であり、base と head が一致することを確認する。

```sh
gh pr view <created-url> --repo <owner>/<repo> \
  --json number,isDraft,baseRefName,headRefName,title,url
```

### 停止条件

既存の pull request が見つかった場合は、新しい Draft pull request を作成しない。

head branch が push 済みでない場合は、`gh pr create` による push または fork の選択へ進まず、`git-usage` へ戻る。

title、body、base、head のいずれかが未確定の場合は、利用者へ確認する。

Draft 以外の pull request 作成、repository の template の変更、reviewer や project の追加は実行しない。

### 代表的な失敗

`head branch not found` の場合は、head の綴り、repository、push 済みの remote branch を `git-usage` で確認する。

base branch が見つからない場合は、repository の default branch または指定された base branch を確認する。

body file を読めない場合は、path と読み取り権限を確認する。

`--head` を省略して push または fork の prompt が表示された場合は、作成を中断し、`--head` を明示して再実行する。
