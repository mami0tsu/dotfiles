# push-branch

現在 branch を `origin` に push する。

## 前提

- [rule-safety.md](rule-safety.md) を読む
- force push しない
- `wip/` branch の push は許可する
- `wip/` branch は Draft PR の叩き台まで許可し、通常 PR 化や merge は不可
- GitHub CLI/API は実行しない

## 確認コマンド

```sh
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git rev-parse --abbrev-ref --symbolic-full-name @{u}
```

detached HEAD なら止める。
upstream が存在しない場合は `-u origin` を付ける。

## 実行前に表示する項目

- repository root
- current branch
- dirty 状態
- upstream の有無
- push 先 remote
- 実行する主要コマンド
- 停止条件

## 実行コマンド

```sh
git push -u origin <branch-name>
```
