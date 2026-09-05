# update-state

保存する値をJSON objectとして権限`0600`の一時ファイルへ置く。
対象repository内で次のcommandを実行する。

```sh
bash "<plugin-root>/skills/tool-workflow-state/scripts/workflow-state.sh" update \
  --workflow-id <workflow-id> \
  --workflow <workflow-name> \
  --subject-kind <subject-kind> \
  --subject <subject-identifier-or-digest> \
  --repository-common-dir <verified-git-common-directory> \
  --namespace <namespace> \
  --expected-revision <revision> \
  --value-file <private-json-file>
```

一時ファイルはcommand終了後に削除する。
revision競合時はstateを再検証し、差分を解決するまで更新しない。
出力されたWorkflow ID、state path、identity、新しいrevisionを次のstate checkpointとして渡す。
Namespaceと保存値も更新結果として利用する。
