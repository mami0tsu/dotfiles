# repair-state-lock

Lock取得時のエラーに表示されたowner tokenを記録する。
対応するprocessまたは別machineの作業が終了済みであることを人間が確認するまで、次のcommandを実行しない。

対象repository内で次のcommandを実行する。

```sh
bash "${CLAUDE_PLUGIN_ROOT}/skills/tool-workflow-state/scripts/workflow-state.sh" repair-lock \
  --workflow-id <workflow-id> \
  --expected-owner-token <owner-token> \
  --confirmed-stale
```

保存中のlockにあるowner tokenが指定値と異なる場合は回収しない。
実行結果が`repaired: true`であることを確認してから、元のstate操作を再実行する。
