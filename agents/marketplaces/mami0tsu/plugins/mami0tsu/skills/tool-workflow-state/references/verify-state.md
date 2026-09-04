# verify-state

対象repository内で次のcommandを実行する。

```sh
bash "${CLAUDE_PLUGIN_ROOT}/skills/tool-workflow-state/scripts/workflow-state.sh" verify \
  --workflow-id <workflow-id> \
  --workflow <workflow-name> \
  --subject-kind <subject-kind> \
  --subject <subject-identifier-or-digest>
```

identityが一致しない場合は停止する。
出力されたstate全体とrevisionを、現在の外部Objectおよび作業情報と照合する。
