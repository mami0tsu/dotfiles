# push-branch

現在 branch を `origin` に push する。

## 前提

- force push しない
- `wip/` branch の push は許可する
- `wip/` branch は Draft PR の叩き台まで許可し、通常 PR 化や merge は不可
- GitHub CLI/API は実行しない

## 手順

1. `common/context.md`、`common/safety.md`、`common/execution-plan.md` を読む。
2. 現在 branch を取得する。
3. detached HEAD なら止める。
4. 実行計画を表示する。
5. push する。

## コマンド

```sh
git push -u origin <branch-name>
```
