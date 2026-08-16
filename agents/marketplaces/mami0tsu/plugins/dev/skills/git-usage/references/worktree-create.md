# Worktree Create

新しい作業場所を `wt.basedir` の下に作成する。
worktree 名と branch 名を分け、起点を明示する。

## やること

1. branch の状態を確認する
2. worktree を作成する
3. 作成結果を確認する

### 1. branch の状態を確認する

worktree 名は `<ticket-id>-<short-description>`、branch 名は `<type>/<ticket-id>/<short-description>` とする。
同じ branch が存在するか、worktree に割り当てられているかを確認する。

```sh
git branch --list '<branch>'
git wt --json --nocd
```

同じ branch が worktree に割り当てられている場合は、既存 path を報告して作成操作を終了する。
branch が存在せず、通常の新規作業を始める場合は、remote の default branch を確認して fetch する。
stacked PR の branch を作る場合は、親 branch を確認して起点にする。

### 2. worktree を作成する

新しい branch は、確認済みの起点を指定して作成する。

```sh
git wt --nocd -b <branch> <worktree> <start-point>
```

通常の start-point は、fetch 済みの `<remote>/<default-branch>` である。
stacked PR では、確認済みの親 branch を start-point にできる。

既存 branch がどの worktree にも割り当てられていない場合は、start-point を指定せず再利用する。

```sh
git wt --nocd -b <branch> <worktree>
```

コマンドが最後に出力する absolute path を、後続コマンドの working directory に使う。

### 3. 作成結果を確認する

一覧の path と branch が作成内容に一致し、新しい worktree が clean であることを確認する。

```sh
git wt --json --nocd
git -C <path> status --short --branch
```

## やらないこと

- start-point を省略して新しい branch を作成しない
- 同じ branch が worktree に割り当てられている場合に作成コマンドを実行しない
- `--force` や `--ignore-other-worktrees` で割り当ての競合を回避しない
- primary worktree が作業 branch を checkout している場合に、自動で branch を切り替えない
- 作成済みの directory を削除または上書きしない
- stacked PR の構築や管理をこの操作で行わない

## 参考情報

- 公式リポジトリ：[k1LoW/git-wt](https://github.com/k1LoW/git-wt)
