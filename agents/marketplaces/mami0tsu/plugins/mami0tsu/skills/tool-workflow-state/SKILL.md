---
name: tool-workflow-state
description: >-
  shell scriptを使い、Git common directoryにある作業stateを初期化、検証、更新、完了するためのTool。
  複数worktreeや人間待ちをまたぐ設計と実装の進行状況を安全に保存するときに使う。
allowed-tools: >-
  Bash(bash */skills/tool-workflow-state/scripts/workflow-state.sh *)
---

# tool-workflow-state

## 制約

- 1つの操作ごとに、対応するreferenceを1つだけ読む。
- referenceにない操作はしない。
- stateは対象repositoryのGit common directory配下へ保存する。
- Issue本文、Document本文、comment本文、credentialをstateへ保存しない。
- 保存禁止情報を別名のfieldへ移して検査を迂回しない。
- lock取得失敗、revision競合、破損したJSONを手作業で迂回しない。
- 完了時もstate fileを削除しない。
- 実装変更時は`scripts/test-workflow-state.sh`で複数worktree、revision競合、identity照合、lock競合、symbolic link、書込失敗時のcleanup、保存禁止fieldを確認する。
- reference内の`<plugin-root>`は、このSkillの配置先から2階層上にあるplugin directoryへ置き換える。
- Claude Codeでは`${CLAUDE_PLUGIN_ROOT}`、CodexではSkill catalogに表示された`SKILL.md`の絶対pathから`<plugin-root>`を解決する。

## ユースケース

**state lifecycle**

| ユースケース | 用途 |
| --- | --- |
| [`complete-state`](references/complete-state.md) | 完了条件を満たしたstateへ完了結果を記録する。 |
| [`initialize-state`](references/initialize-state.md) | 新しい作業stateをGit common directoryへ作る。 |
| [`update-state`](references/update-state.md) | 検証済みrevisionの一つのnamespaceを更新する。 |
| [`verify-state`](references/verify-state.md) | 保存済みidentityを照合してstateを取得する。 |
