# Worktree list

repository に登録された worktree の path、branch、現在地を確認する。
後続の操作では、JSON に含まれる path と branch を使う。

## やること

1. `git wt` の利用可否を確認する
2. worktree を一覧表示する

### 1. `git wt` の利用可否を確認する

Git repository 内で次のコマンドを実行する。

```sh
git wt -v
```

コマンドが失敗した場合は、`git worktree` へ切り替えず停止する。

### 2. worktree を一覧表示する

後続操作で処理できる形式にするため、JSON で取得する。

```sh
git wt --json --nocd
```

- `--json`：出力を機械処理できる形式にする
- `--nocd`：shell integration による directory 移動を抑止する
- `current` が `true` の要素：現在の worktree を示す

## やらないこと

- `git wt` が利用できない場合に `git worktree` へ切り替えない
- 一覧取得と同時に worktree の状態を変更しない

## 参考情報

- 公式リポジトリ：[k1LoW/git-wt](https://github.com/k1LoW/git-wt)
