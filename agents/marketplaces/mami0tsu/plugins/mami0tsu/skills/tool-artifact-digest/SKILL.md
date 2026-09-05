---
name: tool-artifact-digest
description: >-
  shell scriptを使い、設計本文と構造化された承認対象を共通規則で正規化してSHA-256 digestを求めるTool。
  Issue、Wiki、Git管理Document、stateの間で同じ内容を照合するときに使う。
allowed-tools: >-
  Bash(bash */skills/tool-artifact-digest/scripts/artifact-digest.sh *)
---

# tool-artifact-digest

## 制約

- 1つの操作ごとに、対応するreferenceを1つだけ読む。
- referenceにない正規化を加えない。
- 本文やJSONをcommand line argumentへ直接渡さない。
- 入力fileを使う場合は、通常fileであり、現在の利用者だけが読める権限にする。
- digestは`sha256:`を先頭に付けた小文字64桁の16進数として返す。
- 実装変更時は`scripts/test-artifact-digest.sh`で改行、末尾改行、JSONのkey順、異常入力を確認する。
- reference内の`<plugin-root>`は、このSkillの配置先から2階層上にあるplugin directoryへ置き換える。
- Claude Codeでは`${CLAUDE_PLUGIN_ROOT}`、CodexではSkill catalogに表示された`SKILL.md`の絶対pathから`<plugin-root>`を解決する。

## ユースケース

**artifact digest**

| ユースケース | 用途 |
| --- | --- |
| [`digest-json`](references/digest-json.md) | 承認対象などのJSONをkey順に依存しない形式へ正規化する。 |
| [`digest-text`](references/digest-text.md) | 設計本文などのUTF-8 textを改行差に依存しない形式へ正規化する。 |
