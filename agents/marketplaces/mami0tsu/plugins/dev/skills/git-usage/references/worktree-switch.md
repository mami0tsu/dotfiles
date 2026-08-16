# Worktree Switch

既存worktreeのabsolute pathを取得し、後続コマンドのworking directoryに使う。
AIのコマンド実行間でcurrent directoryが維持されることを前提にしない。
[Worktree List](worktree-list.md)に従い、切り替え先のbranchとpathを確認済みであることを前提とする。

## やること

1. worktreeのabsolute pathを取得する
2. working directoryを確認する

### 1. worktreeのabsolute pathを取得する

JSONから取得したbranchまたはpathを指定する。

```sh
git wt --nocd <branch|path>
```

コマンドが最後に出力するabsolute pathを、後続コマンドのworking directoryに指定する。
別のコマンド実行へcurrent directoryが引き継がれるとは判断しない。

### 2. working directoryを確認する

取得したpathを明示して、repository root、branch、変更状態を確認する。

```sh
git -C <path> rev-parse --show-toplevel
git -C <path> status --short --branch
```

repository rootまたはbranchが一覧の値と一致しない場合は、後続操作へ進まない。

## やらないこと

- 一覧にない名前を `git wt` に渡さない
- pathのbasenameをworktree名として使わない
- shell integrationによるdirectory移動を前提にしない
- 前のコマンドで変更したcurrent directoryを次のコマンドでも使えると判断しない
- 切り替えと同時にworktreeやbranchを作成しない

## 参考情報

- 公式リポジトリ：[k1LoW/git-wt](https://github.com/k1LoW/git-wt)
