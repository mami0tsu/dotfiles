---
name: retrospective
description: 完了した作業から、Agent Rules、Agent Skills、権限設定の改善候補と、ユーザーへ実行許可を求めたコマンドを抽出し、機械可読な YAML で記録する。開発フローの完了時、振り返りの作成時、許可履歴からデフォルト許可設定の更新候補を検討するときに使う。
---

# Retrospective

完了した作業の履歴を調べ、[YAML template](assets/retrospective.yaml) に従って `.agent/retrospectives/<ticket-id>.yaml` を生成する。
ticket ID は英数字で始まる128文字以内の英数字、`.`、`_`、`-` に限定する。
出力pathを解決し、`.agent/retrospectives/` の直下にあることを確認する。

## 記録対象

`findings` には、Agent Rules、Agent Skills、権限設定の変更によって AI の振る舞いを改善できる事柄だけを記録する。
実装内容、作業成果、感想、改善へ結び付かない出来事は記録しない。
出来事は、提案を判断できる最小限の根拠として `evidence` に置く。

`category` は `agent_rule`、`agent_skill`、`permission` のいずれかにする。
改善対象のファイルが分かる場合は、repository からの相対 path を `targets` に記録する。

## 許可要求

実際にユーザーへ実行許可を求めたコマンドを、承認、拒否、中断の結果を問わず `permission_requests` に記録する。
sandbox 内で失敗しただけのコマンドと、許可を求めずに実行したコマンドは含めない。

`outcome` は `approved_succeeded`、`approved_failed`、`denied`、`cancelled` のいずれかにする。
許可要求で提示した prefix がある場合は `requested_prefix` にそのまま記録する。

反復して使う対象限定のコマンドは、`default_permission.decision` を `candidate` として許可候補の prefix を記録する。
削除、履歴の書き換え、公開、権限を変更するコマンドと、対象を限定できないコマンドは `rejected` にする。
情報が足りない場合は `deferred` にする。

`candidate` の prefix は、固定した実行ファイルと安全性を判断できるsubcommandまでに限定する。
秘密値、wildcard、redirection、shellの制御演算子を含む場合は `rejected` にする。
prefixだけでは書き込み対象を限定できない場合は `rejected` または `deferred` にする。

デフォルト許可設定は更新しない。
候補を人間が確認した別の変更で更新する。

## 出力

該当する記録がない `findings` または `permission_requests` は空の配列にする。
template の key を追加、削除、改名しない。
すべてのfieldについて、認証情報、個人情報、未公開の機密情報を記録しない。
構造を示すためにコマンドの一部を残す必要がある場合だけ、機密値を `<redacted>` に置き換える。

出力後に次のコマンドを実行し、[JSON Schema](assets/retrospective.schema.json)への適合を確認する。

```sh
<skill-dir>/scripts/validate.py .agent/retrospectives/<ticket-id>.yaml
```
