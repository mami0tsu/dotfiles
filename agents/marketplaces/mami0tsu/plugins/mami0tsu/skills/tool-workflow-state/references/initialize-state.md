# initialize-state

対象repository内で次のcommandを実行する。

```sh
bash "${CLAUDE_PLUGIN_ROOT}/skills/tool-workflow-state/scripts/workflow-state.sh" init \
  --workflow-id <workflow-id> \
  --workflow <workflow-name> \
  --subject-kind <subject-kind> \
  --subject <subject-identifier-or-digest>
```

同じWorkflow IDのstateが存在する場合は上書きしない。
出力されたstate path、identity、revisionを利用する。
