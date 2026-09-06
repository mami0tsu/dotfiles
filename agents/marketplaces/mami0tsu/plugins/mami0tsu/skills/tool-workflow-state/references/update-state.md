# update-state

保存する値をJSON objectとして権限`0600`の一時ファイルへ置く。
対象repository内で次のcommandを実行する。

```sh
bash "<plugin-root>/skills/tool-workflow-state/scripts/workflow-state.sh" update \
  --workflow-id <workflow-id> \
  --workflow <workflow-name> \
  --subject-kind <subject-kind> \
  --subject <subject-identifier-or-digest> \
  --namespace <namespace> \
  --expected-revision <revision> \
  --value-file <private-json-file>
```

一時ファイルはcommand終了後に削除する。
保存済みidentityにあるGit common directoryは、対象repositoryから内部で解決した値と照合する。
更新値にはJSON Merge Patchを使い、`null`を指定したfieldは保存済みnamespaceから削除する。
`operation_envelope`と`operation_envelopes`は内部をmergeせず、指定されたJSON値全体で置き換える。
この置換では、入れ子にある`null`とfield構成を維持する。
Pending operationを完了済みへ移す場合は、同じ更新で完了済み操作を追加し、対応するpending operationへ`null`を指定する。
revision競合時はstateを再検証し、差分を解決するまで更新しない。
出力されたWorkflow ID、state path、identity、新しいrevisionを次のstate checkpointとして渡す。
Namespaceと保存値も更新結果として利用する。
