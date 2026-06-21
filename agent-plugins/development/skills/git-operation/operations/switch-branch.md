# switch-branch

既存 branch に切り替える。新規 branch 作成は扱わない。

## 手順

1. `common/context.md` と `common/safety.md` を読む。
2. repository root、現在 branch、dirty 状態を取得する。
3. 対象 branch が存在することを確認する。
4. dirty なら状態を表示し、ユーザー確認がある場合だけ続行する。
5. branch を切り替える。

## コマンド

```sh
git switch <branch-name>
```

remote branch から local tracking branch を作る必要がある場合は、ユーザーに確認してから実行する。

```sh
git switch --track origin/<branch-name>
```
