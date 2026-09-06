# verify-commit-reachable

## 情報源

- 公式ドキュメント：[REST API endpoints for commits](https://docs.github.com/en/rest/commits/commits#compare-two-commits)
- 検証バージョン：`gh version 2.96.0 (nixpkgs)`
- 確認コマンド：`gh api --help`

## 目的

完全なcommit OIDが、指定したmerge先branchから到達可能であることを認証済みGitHub APIで確認する。

## 前提条件

- `owner/repo`形式のrepository名
- 完全なcommit OID
- 記録済みのmerge先branch

## 推奨コマンド

```sh
gh api --method GET \
  'repos/<owner>/<repo>/compare/<full-commit-oid>...<percent-encoded-merge-target-branch>'
```

## 結果の確認

応答の`status`が`ahead`または`identical`であり、比較のbase commitが入力した完全なcommit OIDと一致することを確認する。
この結果は、merge先branchが対象commitを含むことだけを表す。

## 停止条件

`status`が`behind`または`diverged`の場合は停止する。
Repository、commit、merge先branchのいずれかを確認できない場合も停止する。

## 代表的な失敗

`404 Not Found`ではrepository、commit、branch、認証権限を確認する。
Branch名を既定branchや同名の別branchへ置き換えない。
