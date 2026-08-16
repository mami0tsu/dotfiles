---
name: ticket-usage
description: provider 非依存の契約で開発 ticket を取得、検索、作成、更新し、担当者、状態、親子関係、block 関係、正本 URL を扱うときに使う。Linear または Jira の adapter へ委譲する。
allowed-tools: >-
  Bash(git config --local --get agent.ticket.provider)
---

# Ticket Usage

呼び出し元の flow と ticket provider の間に、[ticket contract](references/contract.md) を置く。
provider 固有の object を flow の状態へ渡さない。

## provider を解決する

repository 内で次の設定を読む。

```sh
git config --local --get agent.ticket.provider
```

値が `linear`なら `$linear-usage`へ操作を委譲する。
値が `jira`なら `$jira-usage`へ操作を委譲する。
設定がない場合は、対応済み provider と保存先を示して人間へ確認する。
承認された場合だけ次を実行する。

```sh
git config --local agent.ticket.provider <linear-or-jira>
```

repository local config は Git common directory で共有されるため、linked worktree ごとに保存し直さない。
設定値は空白を補正せず、`linear`または`jira`との完全一致だけを受理する。
空または未設定なら人間確認へ進み、それ以外は provider 名と設定 key を含む `unsupported-provider`として停止する。
provider を特定できない URL でも停止する。
別 provider へ自動で切り替えない。

## ticket を読み書きする

読み取り結果は contract の field へ正規化する。
呼び出し元には provider 名、ticket ID、正本 URL を常に返す。

書き込み前には、対象 ticket と期待する現在値を relation を含めて再取得する。
作成後または更新後にも再取得し、担当者、状態、親、block 関係を検証する。
provider が要求された関係を表現できない場合は、近い relation へ置き換えず、書き込み前に停止する。

同じ workflow の再開時は、呼び出し元が workflow state に記録した ticket ID を使う。
title 検索だけで作成済み ticket を推測しない。
作成 response の正本 ID は、他の書き込みへ進む前に workflow state へ保存する。
ID を保存できた場合は `get`で期待値を比較し、不足分だけを更新する。
作成成功後に ID を保存できなかった可能性がある場合は、再作成せず、親配下の候補を提示して人間へ確認する。

## 人間の判断を残す

provider の選択、担当者の変更、状態遷移、親子関係、block 関係の変更は、呼び出し元 flow が承認範囲を確定してから実行する。
この Skill は承認を代行しない。

取得できない field と表現できない relation を区別して報告する。
一部だけ書き込むと ticket graph が承認内容と異なる場合は、全書き込みを停止する。
