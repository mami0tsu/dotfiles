# complete-state

完了結果をJSON objectとして権限`0600`の一時ファイルへ置く。
対象repository内で次のcommandを実行する。

```sh
bash "${CLAUDE_PLUGIN_ROOT}/skills/tool-workflow-state/scripts/workflow-state.sh" complete \
  --workflow-id <workflow-id> \
  --expected-revision <revision> \
  --result-file <private-json-file>
```

一時ファイルはcommand終了後に削除する。
完了したstate fileは監査と再参照のために残す。
