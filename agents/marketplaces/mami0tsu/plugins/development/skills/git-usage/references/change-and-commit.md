# 変更を commit する

## 情報源

- 公式ドキュメント：[git-add](https://git-scm.com/docs/git-add)、[git-commit](https://git-scm.com/docs/git-commit)、[git-status](https://git-scm.com/docs/git-status)、[git-diff](https://git-scm.com/docs/git-diff)、[git-show](https://git-scm.com/docs/git-show)
- 検証バージョン：`git version 2.55.0`
- 確認コマンド：`git --version`、`git add --help`、`git commit --help`、`git status --help`、`git diff --help`、`git show --help`

## 意図した path を commit する

### 目的

変更範囲を確認し、指定した path だけを一つの説明可能な commit として記録する。

### 前提条件

repository の commit message 規約と、commit に含める path が確定している。

`git status --short --branch`、`git diff`、`git diff --check` を実行済みである。

### 推奨コマンド

```sh
git add -- <path> [<path>...]
git diff --staged --check
git diff --staged
git commit -m '<type>: <summary> <ticket-id>'
git status --short --branch
git show --stat --oneline HEAD
```

`--` の後には確認済みの具体的な path だけを指定する。

commit message の repository 規約がある場合は、規約を優先する。

### 結果の確認

`git show --stat --oneline HEAD` に、意図した commit message と path だけが表示されることを確認する。

`git status --short --branch` で、残す予定だった未 commit の変更だけが残っていることを確認する。

### 停止条件

stage 済みの差分に意図しない path、secret、生成物、他者の変更が含まれる場合は commit しない。

`git diff --staged --check` が問題を報告する場合は、問題を直してから差分を再確認する。

pre-commit hook が失敗した場合は、`--no-verify` を使わず、失敗内容を確認して利用者へ報告する。

### 代表的な失敗

`nothing to commit` は指定した path に stage 済みの差分がないことを示す。

`git status --short --branch` と `git diff --staged` で、path の指定と stage 状態を確認する。

commit 後に意図しない path が入った場合は、履歴を自動で書き換えない。

push 前なら、修正方針を利用者へ確認する。
