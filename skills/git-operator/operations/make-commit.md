# make-commit

staged 変更を commit する。ユーザーが対象ファイルを指定した場合だけ、その範囲を stage してよい。

## 前提

- `git add -A` は原則使わない
- ユーザー指定がない場合は staged 変更だけ commit する
- 通常 branch では commit message 末尾に ticket-id を付ける
- `wip/` branch では ticket-id なし commit を許可する

## 手順

1. `common/context.md`、`common/safety.md`、`common/naming.md` を読む。
2. 現在 branch と staged/unstaged/untracked の状態を確認する。
3. ユーザーが file path を指定している場合だけ、該当 file を stage する。
4. staged 変更がなければ止める。
5. 通常 branch では branch 名から ticket-id を抽出する。
6. ticket-id が取れない場合は、ticket-id 入力、ticket-id なし続行、中止の選択肢を出す。
7. Conventional Commits の type と summary を決める。
8. commit する。

## コマンド

指定ファイルだけ stage する場合:

```sh
git add <path>...
```

commit:

```sh
git commit --message "<type>: <summary> <ticket-id>"
```

`wip/` branch で ticket-id なしの場合:

```sh
git commit --message "<type>: <summary>"
```
