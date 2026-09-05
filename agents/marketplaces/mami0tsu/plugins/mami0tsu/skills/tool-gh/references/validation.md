# 検証記録

## 2026-09-04：Issue作成の通常経路

- 実行環境：macOS、`gh version 2.96.0 (nixpkgs)`
- 入力：承認済みtitleと権限`0600`のbody fileからIssueを一件作り、作成内容を確認する。
- 対象ユースケース：`create-issue`、`read-issue`、`find-issues`
- 読み込んだreference：`create-issue.md`、`read-issue.md`、`find-issues.md`
- 実行したhelp：なし
- 結果：作成前確認、作成command、再取得による確認、曖昧な結果を再作成せず候補提示する停止条件をreferenceだけから選択できた。
- 更新内容：初回試験で不足していた候補検索を`find-issues`として追加し、通常経路では`--help`を読まない制約を明記して再試験した。

GitHubへの書き込みは行わず、command選択と停止条件を読み取り専用で検証した。

## 2026-09-05：本文操作とremote Document読取

- 実行環境：macOS、`gh version 2.96.0 (nixpkgs)`
- 入力：標準入力の本文からIssueとDraft PRを操作し、別repositoryの完全なcommit OIDからDocumentを読む。
- 対象ユースケース：`create-issue`、`update-issue`、`create-draft-pr`、`read-file-at-commit`
- 読み込んだreference：`create-issue.md`、`update-issue.md`、`create-draft-pr.md`、`read-file-at-commit.md`
- 実行したhelp：`gh api --help`
- 結果：本文操作は専用scriptのprocess内で権限`0600`の一時fileを使い、成功時と失敗時の両方で削除することをtestで確認した。Remote読取はrepository、完全なcommit OID、pathを明示する構文をローカルhelpと照合した。

GitHubへの書き込みとremote fileの取得は行っていない。

## 2026-09-04：Version差のフォールバック

- 実行環境：macOS、`gh version 2.96.0 (nixpkgs)`
- 入力：referenceと異なるversionを想定し、Issueへ親関係を設定する。
- 対象ユースケース：`set-issue-parent`
- 読み込んだreference：`set-issue-parent.md`
- 実行したhelp：`gh issue edit --help`
- 結果：確認範囲を対象subcommandの`--parent`へ限定し、構文または意味が不一致なら書き込まず停止する判断を確認した。

実環境のversionはreferenceと一致したため、version差そのものは再現していない。
GitHubへの書き込みは行わず、ローカルhelpとの構文照合だけを実行した。
