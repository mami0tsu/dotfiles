# initialize-state

対象repository内で次のcommandを実行する。

```sh
bash "<plugin-root>/skills/tool-workflow-state/scripts/workflow-state.sh" init \
  [--workflow-id <workflow-id>] \
  --workflow <workflow-name> \
  --subject-kind <subject-kind> \
  --subject <subject-identifier-or-digest>
```

新規作業でWorkflow IDを省略した場合は、安全なWorkflow IDを生成する。
同じWorkflow IDのstateが存在する場合は上書きしない。
出力されたWorkflow ID、state path、identity、revisionを利用する。
