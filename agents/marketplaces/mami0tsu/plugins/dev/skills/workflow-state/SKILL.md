---
name: workflow-state
description: repository の Git common directory に workflow 状態を保存し、複数 worktree や人間待ちをまたぐ実行を初期化、照合、更新、再開、完了するときに使う。
allowed-tools: >-
  Bash(python3 ${CLAUDE_PLUGIN_ROOT}/skills/workflow-state/scripts/workflow_state.py:*)
---

# Workflow State

トップレベルの workflow ごとに一つの状態を持つ。
下位 flow は別の状態ファイルを作らず、同じ状態の namespace を更新する。

## 状態を初期化する

worktree が clean であり、ticket または PR の正本 URL が確定してから初期化する。

```sh
python3 <skill-dir>/scripts/workflow_state.py init \
  --workflow-id <workflow-id> \
  --workflow <workflow-name> \
  --subject-kind <ticket-or-pr> \
  --subject <canonical-url>
```

`workflow-id`には、provider の識別子を含む衝突しない値を使う。
script は repository、現在の branch、開始 commit を記録し、Git common directory 配下の `agent-workflows/`へ保存する。

## 状態を再開する

保存済みの識別情報を外部状態と照合してから再開する。

中断後に識別情報を失った場合は、本文を表示しない `show`で取得する。

```sh
python3 <skill-dir>/scripts/workflow_state.py show --workflow-id <workflow-id>
```

```sh
python3 <skill-dir>/scripts/workflow_state.py verify \
  --workflow-id <workflow-id> \
  --workflow <workflow-name> \
  --subject-kind <ticket-or-pr> \
  --subject <canonical-url> \
  --branch <recorded-branch> \
  --start-commit <recorded-commit>
```

別の worktree から再開する場合も、現在の branch で識別情報を上書きしない。
記録済みの branch と開始 commit を引数へ渡す。
いずれかが一致しなければ停止する。

## 下位 flow の状態を更新する

namespace は flow 名と対応させる。
値は JSON object とし、権限を `0600`にした一時ファイルから渡す。

```sh
python3 <skill-dir>/scripts/workflow_state.py put \
  --workflow-id <workflow-id> \
  --namespace <flow-name> \
  --value-file <private-json-file>

python3 <skill-dir>/scripts/workflow_state.py get \
  --workflow-id <workflow-id> \
  --namespace <flow-name>
```

credential、comment 本文、review 本文は保存しない。
script は代表的な機密 field 名と本文 field 名を拒否するが、値の意味までは判定できない。
禁止 field を別名へ変えて検査を迂回しない。
外部 object は URL、ID、OID と判断結果だけで参照する。

## workflow を完了する

全工程の完了を外部状態から確認した場合だけ状態を削除する。

```sh
python3 <skill-dir>/scripts/workflow_state.py complete --workflow-id <workflow-id>
```

中断や人間待ちでは `complete`を実行しない。
lock を期限内に取得できない場合や状態が壊れている場合は、ファイルを手作業で修復せず停止する。
