# commit-changes

staged 変更を commit する。
ユーザーが対象ファイルを指定した場合だけ、その範囲を stage してよい。

## 前提

- [rule-safety.md](rule-safety.md) と [rule-naming.md](rule-naming.md) を読む
- ユーザー指定がない場合は staged 変更だけ commit する
- 通常 branch では commit message 末尾に ticket-id を付ける
- `wip/` branch では ticket-id なし commit を許可する

## 確認コマンド

```sh
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git diff --cached --stat
git diff --cached --name-status
```

ユーザーが file path を指定している場合だけ stage する:

```sh
git add <path>...
git status --short --branch
git diff --cached --stat
git diff --cached --name-status
```

staged 変更がなければ止める。
通常 branch では branch 名から ticket-id を抽出する。
ticket-id が取れない場合は、ticket-id 入力、ticket-id なし続行、中止の選択肢を出す。

## 実行前に表示する項目

- repository root
- current branch
- staged file 一覧
- unstaged/untracked の有無
- commit message
- 実行する主要コマンド
- 停止条件

## 実行コマンド

通常 branch:

```sh
git commit --message "<type>: <summary> <ticket-id>"
```

`wip/` branch で ticket-id なしの場合:

```sh
git commit --message "<type>: <summary>"
```

commit summary は上位 skill から渡された値を優先する。
未指定の場合は staged diff から保守的に作る。
