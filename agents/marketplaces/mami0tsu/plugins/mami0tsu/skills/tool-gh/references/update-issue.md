# update-issue

## 情報源

- 公式ドキュメント：[GitHub CLI `gh issue edit` manual](https://cli.github.com/manual/gh_issue_edit)
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- 確認コマンド：`gh --version`、`gh issue edit --help`

## 目的

Issueのtitle、本文、担当者、labelを承認済みの値へ更新する。

## 前提条件

- `owner/repo`形式のrepository名
- Issue番号またはURL
- 更新前に`read-issue`ユースケースで取得した現在値
- 標準入力から渡す承認済み本文

## 推奨コマンド

本文とtitleを更新する。

```sh
bash "<plugin-root>/skills/tool-gh/scripts/github-body-operation.sh" issue-update \
  --repo <owner>/<repo> --issue <number-or-url> --title '<title>'
```

承認済み本文を標準入力へ送り終えたらEOFを送る。
Scriptはprivate body fileを作成し、`gh issue edit`の終了時に削除する。

承認済みの担当者またはlabelの差分がある場合は、それぞれの追加または削除optionだけを指定する。

```sh
gh issue edit <number-or-url> --repo <owner>/<repo> --add-assignee <login>
gh issue edit <number-or-url> --repo <owner>/<repo> --remove-assignee <login>
gh issue edit <number-or-url> --repo <owner>/<repo> --add-label '<label>'
gh issue edit <number-or-url> --repo <owner>/<repo> --remove-label '<label>'
```

## 結果の確認

`read-issue`ユースケースでIssueを再取得し、承認済みのfieldと一致することを確認する。

## 停止条件

更新前の現在値が取得時から変わっている場合は更新しない。
承認されていないfieldの差分は削除しない。

## 代表的な失敗

担当者またはlabelが存在しない場合は入力を確認し、別の値へ置き換えない。
一部のfieldだけが更新された場合は成功済みの変更を戻さず、未反映の差分を返す。
