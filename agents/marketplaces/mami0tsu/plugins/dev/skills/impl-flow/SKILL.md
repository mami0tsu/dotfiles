---
name: impl-flow
description: 1つの実装 ticket を専用 worktree、branch、commit、push、Draft PR、振り返りまで進め、ticket の blocker 関係から standalone または stacked PR の base を決める開発フロー。承認済み ticket を実装するときに使う。
---

# Implementation Flow

承認済みの実装 ticket を一件だけ受け取る。
1つの ticket、branch、worktree、pull request を一対一に対応させ、ticket の block 関係を pull request の依存順へ写す。

受け入れ条件か実装範囲が不足している場合は実装しない。
呼び出し元へ不足を返し、設計または ticket の更新後に再開する。

## workflow state

`workflow-state`を使い、トップレベル workflow の namespace `impl-flow`へ次の識別情報を保存する。

- ticket provider、ticket ID、正本 URL
- repository、default branch、base branch、head branch、worktree path
- base commit、head commit、remote の期待 OID
- blocker ticket ID、blocker pull request URL、stack ID
- 作成した pull request URL

credential、ticket 本文、pull request 本文、review comment 本文は保存しない。
下位 flow の状態ファイルを新しく作らない。

再開時は `ticket-usage`で ticket と relation を、`gh-usage`で pull request と stack を再取得する。
保存済みの ticket、base、head、pull request のいずれかが現在値と一致しなければ停止する。

## base branch を決める

repository の remote と default branch は `git-usage`で取得する。
ticket は `ticket-usage`で relation を含めて取得し、`blockedBy`を実行順序として扱う。
親子関係から blocker を推測しない。

各 blocker ticket について、workflow state に保存済みの pull request URL を優先する。
保存値がない場合は、正本 ticket URL を本文に含む pull request を repository 内の全 state から列挙する。
候補の body にある `Ticket`欄が正本 ticket URL と完全一致し、head branch が ticket ID を含むことを確認して一件に確定する。

候補が0件なら未実装の依存として待機する。
候補が複数ある場合、`Ticket`欄がない場合、URL または ticket ID が一致しない場合は停止する。
確定後に state、base、head、merge commit、stack 所属を取得する。

base branch は次の規則で一件に決める。

1. blocker がないか、すべての blocker pull request が default branch へ merge 済みなら、default branch を base にする。
2. 未merge blocker が一件なら、その blocker pull request の head branch を base にする。
3. 未merge blocker が複数あり、すべて同じ stack に属するなら、stack 内で最上位にある blocker pull request の head branch を base にする。
4. 未merge blocker が複数の stack に分かれるか、stack 外の複数 branch に分かれるなら待機する。

選んだ base branch を fetch し、remote OID を記録する。
blocker pull request の head branch、ticket の blocker、stack 順序が互いに一致しない場合は実装を開始しない。

## worktree と branch

`git-usage`を使い、ticket ID を含む専用 branch と専用 worktree を1つ用意する。
新しい branch は、確認済みの base branch の remote OID を起点にする。

既存 worktree を再利用できるのは、次の条件をすべて満たす場合だけである。

- 保存済みの ticket ID、branch、worktree path が一致する。
- worktree が clean である。
- branch の merge-base が記録済み base commit と一致する。
- branch が別の ticket または pull request に対応していない。

base、head、ticket、pull request の対応を一件に確定できなければ停止する。
dirty な worktree を自動で stash しない。

## 実装と commit

ticket の範囲内だけを実装し、対象変更に必要な test、lint、build、文書を検査する。
呼び出し元が `git-usage`で変更を関心別に commit する。

worktree が clean になったら、base と target を完全な commit OID で `pre-push-review`へ渡す。
通常検証、専門 sub-agent の敵対的検証、difit の人間レビューを完了し、コメントが0件になるまで push しない。

finding を修正した場合は新しい関心別 commit を作成する。
同じ `pre-push-review`を新しい target commit で再開する。

## push と Draft pull request

初回 push は `git-usage`で remote と branch を明示する。
push 後に remote head OID が local HEAD と一致することを確認する。

repository の pull request template を優先する。
template がなければ [assets/pull_request_template.md](assets/pull_request_template.md) を使う。
複数の repository template があり、選択が承認済み成果物にない場合は停止する。
body file の `Ticket`欄には正本 ticket URL を一件だけ記載する。

`gh-usage`で既存 pull request がないことを確認し、base、head、title、body file、Draft を明示して一件作成する。
作成直後に Draft 状態、base、head、title、body、URLを再取得し、`Ticket`欄を含む期待値と比較する。

base が default branch なら standalone pull request として扱い、stack 操作は行わない。
base が blocker branch なら、base に選んだ blocker pull request の stack を bottom まで取得する。
既存 stack の全 URL と作成した pull request の URL を bottom から top の順へ並べ、`gh stack link`で既存 Draft pull request を stack 化する。
二件未満の URL を `gh stack link`へ渡さない。

stack 化後は各 pull request の base、head、Draft 状態、stack ID、順序を再取得する。
一部だけが更新された場合は再実行せず、現在値と成功した変更を報告する。

## stack の rebase と force push

履歴を書き換える前に、対象 branch が workflow state の active stack に含まれ、worktree、ticket、pull request、base、head が現在値と一致することを検証する。
各 remote branch の OID を fetch 後に記録する。

stack の rebase 後に公開済み branch を更新できるのは、人間が履歴変更を明示的に承認した場合だけである。
各 branch について、rebase 後の新しい base と target を完全な commit OID で固定し、通常検証と `pre-push-review`を完了する。
検証済み base、target と active stack identity が現在値に一致する branch だけを bottom から top の順に push する。

push には記録済み remote OID を指定した `--force-with-lease=<branch>:<expected-oid>`を使う。
引数なしの `--force-with-lease`、`--force`、active stack 外の branch、取得後に OID が変わった branchへの force push は拒否する。

各 push 後に remote OID が local target OID と一致することを確認する。
下位 branch の push が失敗した場合、または remote OID が期待値と異なる場合は、上位 branch を push せず残りを停止する。
更新後はすべての remote OID と pull request の base、head、stack 順序を再取得する。

## 振り返りと完了

Draft pull request の作成と検証が終わった直後に `retrospective`を実行する。
`.agent/`が Git の除外対象であり、追跡およびstageの対象外であることを確認する。

`retrospective`には ticket ID、作業履歴、実際に求めた実行許可を渡す。
pull request URL と振り返りの検証結果を workflow state に記録し、呼び出し元へ返す。

この flow は pull request を ready にせず、merge せず、review thread を resolve しない。
Draft pull request と振り返りを検証できた時点で完了する。

## 検証記録

standalone、stack 最下層、stack 上位と停止経路は [references/validation.md](references/validation.md) に記録する。
