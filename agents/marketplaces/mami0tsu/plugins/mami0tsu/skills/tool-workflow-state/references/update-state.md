# update-state

保存する値をJSON objectとして権限`0600`の一時ファイルへ置く。
対象repository内で次のcommandを実行する。

```sh
bash "${CLAUDE_PLUGIN_ROOT}/skills/tool-workflow-state/scripts/workflow-state.sh" update \
  --workflow-id <workflow-id> \
  --workflow <workflow-name> \
  --subject-kind <subject-kind> \
  --subject <subject-identifier-or-digest> \
  --namespace <namespace> \
  --expected-revision <revision> \
  --value-file <private-json-file>
```

一時ファイルはcommand終了後に削除する。
revision競合時はstateを再検証し、差分を解決するまで更新しない。
